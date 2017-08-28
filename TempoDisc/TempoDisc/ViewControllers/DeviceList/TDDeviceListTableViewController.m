//
//  TDDeviceListTableViewController.m
//  TempoDisc
//
//  Created by Nikola Misic on 2/28/16.
//  Copyright © 2016 BlueMaestro. All rights reserved.
//

#import "TDDeviceListTableViewController.h"
#import <LGBluetooth/LGBluetooth.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "TDDeviceTableViewCell.h"
#import "TDOtherDeviceTableViewCell.h"
#import "TDPressureDeviceTableViewCell.h"
#import <MBProgressHUD/MBProgressHUD.h>
#import "TDDeviceInfoViewController.h"
#import "AppDelegate.h"
#import "TDTempoDisc.h"
#import "TDMovementDeviceTableViewCell.h"
#import "TempoDiscDevice+CoreDataProperties.h"
#import "TDUARTAllDataDownloader.h"
#import "TDMagnetometerDeviceTableViewCell.h"
#import "TDLuminosityDeviceTableViewCell.h"

#define kDeviceScanInterval 2.0

#define kDeviceListUpdateInterval 3.0
#define kDeviceListUpdateScanInterval 1.0

#define kDeviceOutOfRangeTimer 20.0

typedef enum : NSInteger {
	DeviceSortTypeNone = 0,
	DeviceSortTypeName,
	DeviceSortTypeClassID,
	DeviceSortTypeSignalStrength,
} DeviceSortType;

@interface TDDeviceListTableViewController()

@property (nonatomic, strong) NSTimer *timerUpdateList;
@property (nonatomic, assign) DeviceSortType sortType;
@property (nonatomic, strong) NSNumber* deviceFilterId;
@property (nonatomic, strong) NSArray* sortedDeviceList;
@property (nonatomic, strong) TDTempoDisc *selectedDevice;
@property (nonatomic, strong) TDUARTAllDataDownloader *downloader;
@property (nonatomic, assign) BOOL sendingData;
@property (nonatomic, strong) MBProgressHUD *hudBlink;
@property (nonatomic, strong) NSIndexPath *indexPathEdit;

@end

@implementation TDDeviceListTableViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	_dataSource = [@[] mutableCopy];
	[self setupView];
	/**
	 *	Wait until ready to perform scan
	 **/
	_ignoreScan = YES;
	[[LGCentralManager sharedInstance]
	 addObserver:self forKeyPath:@"centralReady" options:NSKeyValueObservingOptionNew context:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleGoToBackgroundNotifications:) name:UIApplicationWillResignActiveNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleReturnToForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
	if ([self isMemberOfClass:[TDDeviceListTableViewController class]]) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handlePeripheralUpdateNotification:) name:kNotificationPeripheralUpdated object:nil];
	}
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	if (!_ignoreScan) {
		[self scanForDevices];
	}
    if (_timerUpdateList) {
        [_timerUpdateList invalidate];
        _timerUpdateList = nil;
    }
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	if (self.scanning) {
		[self stopScan];
	}
    if (_timerUpdateList) {
        [_timerUpdateList invalidate];
        _timerUpdateList = nil;
    }
	[_hudBlink hide:YES];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
	if ([keyPath isEqualToString:@"centralReady"]) {
		if ([LGCentralManager sharedInstance].isCentralReady) {
			__weak typeof(self) weakself = self;
			dispatch_async(dispatch_get_main_queue(), ^{
				//Bluetooth is ready. Start scan.
				[weakself scanForDevices];
				weakself.ignoreScan = NO;
				
				//we dont need to listen to changes anymore since everything is set up
				[[LGCentralManager sharedInstance] removeObserver:self forKeyPath:@"centralReady"];
			});
		}
	}
}

#pragma mark - Private methods

- (void)setupView {
	self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Scan" style:UIBarButtonItemStyleDone target:self action:@selector(buttonScanClicked:)];
}

- (void)handleUpdateTimer:(NSTimer*)timer {
    NSLog(@"In update timer for refresh scan");
    [self scanForDevices];

}

- (void)stopScan {
	[[LGCentralManager sharedInstance] stopScanForPeripherals];
	if (_timerUpdateList) {
		[_timerUpdateList invalidate];
		_timerUpdateList = nil;
	}
    self.scanning = NO;
}

- (void)updateDeviceList {
	[self.tableView reloadData];
}

- (void)scanForDevices {
    if ([LGCentralManager sharedInstance].scanning) {
        [[LGCentralManager sharedInstance] stopScanForPeripherals];
    }
    
    NSSortDescriptor *sortDescriptor;
    sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"uuid" ascending:YES];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
	
	__weak typeof(self) weakself = self;
	[[LGCentralManager sharedInstance]
	 scanForPeripheralsByInterval:kDeviceScanInterval
	 services:nil
	 options:@{CBCentralManagerScanOptionAllowDuplicatesKey : @YES}
	 completion:^(NSArray *peripherals) {
         NSLog(@"Peripheral count is %lu", (unsigned long)[peripherals count]);
         NSMutableArray *devices = [NSMutableArray array];
		 for (LGPeripheral *peripheral in peripherals) {
			 TDTempoDisc *device = [self findOrCreateDeviceForPeripheral:peripheral];
			 if (device) {
				 device.peripheral = peripheral;
                 if ((device.version.integerValue == 22) || (device.version.integerValue == 23)) {
                     [devices addObject:device];
                     NSLog(@"Scanning and device found");
                 }
				 else if (device.version.integerValue == 13) {
					 [devices addObject:device];
					 NSLog(@"Found v13 device");
				 }
				 else if (device.version.integerValue == 27) {
					 [devices addObject:device];
					  NSLog(@"Found v27 device");
				 }
				 else if (device.version.integerValue == 32) {
					 [devices addObject:device];
					 NSLog(@"Found v32 device");
				 }
				 else if (device.version.integerValue == 42) {
					 [devices addObject:device];
					 NSLog(@"Found v42 device");
				 }
				 else if (device.version.integerValue == 52) {
					 [devices addObject:device];
					 NSLog(@"Found v52 device");
				 }
				 else if (device.version.integerValue == 62) {
					 [devices addObject:device];
					 NSLog(@"Found v62 device");
				 }
                 else if (device.version.integerValue == 99) {
                     [devices addObject:device];
                     NSLog(@"Found Pacifi V2 device");
                 }
                 else if (device.version.integerValue == 113) {
                     [devices addObject:device];
                     NSLog(@"Found v113 device");
                 }
                 
			 }
         }
		 
		 NSArray *udid = [weakself.dataSource valueForKey:@"uuid"];
		 for (TDTempoDisc *device in devices) {
			 NSUInteger index = [udid indexOfObject:device.uuid];
			 if (index != NSNotFound) {
				 [weakself.dataSource replaceObjectAtIndex:index withObject:device];
			 }
			 else {
				 [weakself.dataSource addObject:device];
			 }
		 }
		 
		 weakself.dataSource = [[weakself.dataSource sortedArrayUsingDescriptors:sortDescriptors] mutableCopy];
		 
		 [weakself.tableView reloadData];
		 
		 /**
		  *	Looks like it doesnt do anything other than reload table view
		  **/
         if (_timerUpdateList) {
             [_timerUpdateList invalidate];
             _timerUpdateList = nil;
         }
         _timerUpdateList = [NSTimer timerWithTimeInterval:kDeviceListUpdateInterval target:self selector:@selector(handleUpdateTimer:) userInfo:nil repeats:YES];
         [[NSRunLoop mainRunLoop] addTimer:_timerUpdateList forMode:NSRunLoopCommonModes];
    		 
	 }];
}

- (TDTempoDisc*)findOrCreateDeviceForPeripheral:(LGPeripheral*)peripheral {
	/**
	 *	If there is no manufacturer data see if the device is already inserted and return that device.
	 **/
	BOOL hasManufacturerData = [TempoDevice hasManufacturerData:peripheral.advertisingData];
	
	BOOL isBlueMaestroDevice = [TempoDevice isBlueMaestroDeviceWithAdvertisementData:peripheral.advertisingData];
    BOOL isTempoDisc13 = [TempoDevice isTempoDisc13WithAdvertisementDate:peripheral.advertisingData];
    BOOL isTempoDisc22 = [TempoDevice isTempoDisc22WithAdvertisementDate:peripheral.advertisingData];
    BOOL isTempoDisc23 = [TempoDevice isTempoDisc23WithAdvertisementDate:peripheral.advertisingData];
	BOOL isTempoDisc27 = [TempoDevice isTempoDisc27WithAdvertisementDate:peripheral.advertisingData];
	BOOL isTempoDisc32 = [TempoDevice isTempoDisc32WithAdvertisementDate:peripheral.advertisingData];
    BOOL isTempoDisc99 = [TempoDevice isTempoDisc99WithAdvertisementDate:peripheral.advertisingData];
    BOOL isTempoDisc113 = [TempoDevice isTempoDisc113WithAdvertisementDate:peripheral.advertisingData];
	
    if (isTempoDisc13) {NSLog(@"Found Tempo Disc 13");}
    if (isTempoDisc22) {NSLog(@"Found Tempo Disc 22");}
    if (isTempoDisc23) {NSLog(@"Found Tempo Disc 23");}
	if (isTempoDisc27) {NSLog(@"Found Tempo Disc 27");}
	if (isTempoDisc32) {NSLog(@"Found Tempo Disc 32");}
    if (isTempoDisc99) {NSLog(@"Found Pacif-i v2");}
    if (isTempoDisc113) {NSLog(@"Found Tempo Disc 113");}
	
	TDTempoDisc *device = [[TDTempoDisc alloc] init];
	if (isBlueMaestroDevice && hasManufacturerData) {
		[device fillWithData:peripheral.advertisingData name:peripheral.name uuid:peripheral.cbPeripheral.identifier.UUIDString];
        NSLog(@"Refreshing with data");
		return device;
	}
	return nil;
}

- (void)handleGoToBackgroundNotifications:(NSNotification*)note {
	if (!_ignoreScan) {
		[self stopScan];
	}
    if (_timerUpdateList) {
        [_timerUpdateList invalidate];
        _timerUpdateList = nil;
    }
}

- (void)handleReturnToForeground:(NSNotification*)note {
	//reset filters and sort
	_sortType = DeviceSortTypeNone;
	_deviceFilterId = nil;
	[self updateDeviceList];
	
	//resume scanning
	if (!_ignoreScan) {
		[self scanForDevices];
	}
}

- (void)handlePeripheralUpdateNotification:(NSNotification*)note {
	LGPeripheral *peripheral = note.userInfo[kKeyNotificationPeripheralUpdatedPeripheral];
	if (peripheral) {
		TempoDevice *deviceToChange = nil;
		for (TempoDevice *device in self.dataSource) {
			if ([peripheral.UUIDString isEqualToString:device.peripheral.UUIDString]) {
				deviceToChange = device;
				break;
			}
		}
		if (deviceToChange) {
			deviceToChange.peripheral = peripheral;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
            });
        
		}
	}
}

#pragma mark - Public methods

- (void)loadDevices:(NSArray*)devices {
	_dataSource = [devices mutableCopy];
	[self.tableView reloadData];
}

#pragma mark - Actions

- (IBAction)buttonScanClicked:(UIBarButtonItem*)sender {
//	__weak typeof(self) weakself = self;
	_dataSource = [@[] mutableCopy];
	[self.tableView reloadData];
	
    [self scanForDevices];
    
    //Options for filtering, sorting, scanning.  Just activating scanning for the moment.
    /*
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Please select from the following scan options" message:nil preferredStyle:UIAlertControllerStyleAlert];
	
	[alert addAction:[UIAlertAction actionWithTitle:@"Sort Device" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
		
		UIAlertController *sortAlert = [UIAlertController alertControllerWithTitle:@"Please select how you would like the devices sorted" message:nil preferredStyle:UIAlertControllerStyleAlert];
		
		[sortAlert addAction:[UIAlertAction actionWithTitle:@"Name" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
			weakself.sortType = DeviceSortTypeName;
			[weakself updateDeviceList];
		}]];
		
		[sortAlert addAction:[UIAlertAction actionWithTitle:@"Class ID" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
			weakself.sortType = DeviceSortTypeClassID;
			[weakself updateDeviceList];
		}]];
		
		[sortAlert addAction:[UIAlertAction actionWithTitle:@"Signal Strength" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
			weakself.sortType = DeviceSortTypeSignalStrength;
			[weakself updateDeviceList];
		}]];
		
		[sortAlert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
		
		[weakself presentViewController:sortAlert animated:YES completion:nil];
	}]];
	
	[alert addAction:[UIAlertAction actionWithTitle:@"Filter Device" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
		UIAlertController *filterAlert = [UIAlertController alertControllerWithTitle:@"Filter devices to show only devices with a certain Class ID. Please enter a Class ID between 0 (default) and 255" message:nil preferredStyle:UIAlertControllerStyleAlert];
		
		[filterAlert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
			textField.keyboardType = UIKeyboardTypeNumberPad;
		}];
		
		[filterAlert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
			NSInteger number = filterAlert.textFields[0].text.integerValue;
			weakself.deviceFilterId = @(number);
			[weakself updateDeviceList];
		}]];
		
		[filterAlert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
		
		[weakself presentViewController:filterAlert animated:YES completion:nil];
	}]];
	
	[alert addAction:[UIAlertAction actionWithTitle:@"Restart Scan" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
		[weakself scanForDevices];
	}]];
	
	[alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
	
	[self presentViewController:alert animated:YES completion:nil];
     */
}

#pragma mark - Cell fill

- (void)fillTempoDiscCell:(TDDeviceTableViewCell*)cell model:(TDTempoDisc*)device {
    UIImage *lowBattImage = [UIImage imageNamed:@"battery_low"];
    UIImage *mediumBattImage = [UIImage imageNamed:@"battery_medium"];
    UIImage *highBattImage = [UIImage imageNamed:@"battery_high"];
    UIImage *strongRSSIImage = [UIImage imageNamed:@"rssi_high"];
    UIImage *mediumRSSIImage = [UIImage imageNamed:@"rssi_medium"];
    UIImage *lowRSSIImage = [UIImage imageNamed:@"rssi_low"];
    UIImage *unlockedImage = [UIImage imageNamed:@"padlockopen"];
    UIImage *lockedImage = [UIImage imageNamed:@"padlockclosed"];
    UIImage *breachImage = [UIImage imageNamed:@"alert_icon"];
    
    
    if ([device isKindOfClass:[TDTempoDisc class]] || [device isKindOfClass:[TempoDiscDevice class]]) {
        TDTempoDisc* disc = (TDTempoDisc*)device;
        int mode = disc.mode.intValue;
        int remainder = mode % 100;
        remainder = remainder / 10;
        NSLog(@"Mode is %d and remainder is %d", mode, remainder);
        if (remainder > 0) {
            [cell.lockImage setImage:lockedImage];
        } else {
            [cell.lockImage setImage:unlockedImage];
        }
        int breach_count = device.numBreach.intValue;
        if (breach_count > 0) {
            NSLog(@"Breach count is %d", device.numBreach.intValue);
            [cell.alertImage setImage:breachImage];
            cell.labelAlertCount.text = [NSString stringWithFormat:@"%d", breach_count];
        } else {
            [cell.alertImage setHidden:YES];
            [cell.labelAlertCount setHidden:YES];
        }
        cell.classID.text = [NSString stringWithFormat:@"%d", device.globalIdentifier.intValue];
    }

	cell.labelDeviceName.text = device.name;
	NSString *unit = device.isFahrenheit.boolValue ? @"Fahrenheit" : @"Celsius";
	
	cell.labelLogCountValue.text = [NSString stringWithFormat:@"%@ logs", device.intervalCounter.stringValue];
	cell.labelLogIntervalValue.text = [NSString stringWithFormat:@"%@ seconds", device.timerInterval.stringValue];

    cell.dewpointUnits.text = unit;
    cell.temperatureUnits.text = unit;
	cell.labelTemperatureValue.text = [NSString stringWithFormat:@"%.1fº", [TDHelper temperature:device.currentTemperature forDiscDevice:device].floatValue];
	cell.labelHumidityValue.text = [NSString stringWithFormat:@"%.1f%%", device.currentHumidity.floatValue];
	cell.labelDeviceBatteryValue.text = [NSString stringWithFormat:@"%@%%", device.battery.stringValue];
    if (device.battery.integerValue >= 85) {
        [cell.batteryImage setImage:highBattImage];
    }
    if ((device.battery.integerValue < 85) && (device.battery.integerValue >= 70)) {
        [cell.batteryImage setImage:mediumBattImage];
    }
    if (device.battery.integerValue < 70) {
        [cell.batteryImage setImage:lowBattImage];
    }													
	
	if (device.version) {
		cell.labelDeviceVersion.text = [NSString stringWithFormat:NSLocalizedString(@"Version:", nil)];
		cell.labelDeviceVersionValue.hidden = NO;
		cell.labelDeviceVersionValue.text = device.version.stringValue;
	}
	else {
		cell.labelDeviceVersion.text = NSLocalizedString(@"No version info", nil);
		cell.labelDeviceVersionValue.hidden = YES;
	}
	cell.labelDeviceRSSIValue.text = [NSString stringWithFormat:@"%lddB", device.peripheral.RSSI];
    
    if (device.peripheral.RSSI > -90) {
        [cell.RSSIImage setImage:strongRSSIImage];
        
    }
    if ((device.peripheral.RSSI < -90) && (device.peripheral.RSSI >-100)){
        [cell.RSSIImage setImage:mediumRSSIImage];
        
    }
    if (device.peripheral.RSSI < -100){
        [cell.RSSIImage setImage:lowRSSIImage];
        
    }
    
	
	cell.labelDeviceUUIDValue.text = [NSString stringWithFormat:@"%@", device.peripheral ? device.peripheral.UUIDString : device.uuid];
	
	cell.labelDeviceIdentifierValue.text = @"OTHER TEMPO DISC";
	
	if ([device respondsToSelector:@selector(dewPoint)] && device.dewPoint) {
		cell.labelCurrentDewPointValue.text = [NSString stringWithFormat:@"%.1fº", [TDHelper temperature:device.dewPoint forDiscDevice:device].floatValue];
	}
	else {
		cell.labelCurrentDewPointValue.text = @"0";
	}
	
	if ([device isKindOfClass:[TDTempoDisc class]]) {
		if (device.version.integerValue == 23) {
			cell.labelDeviceIdentifierValue.text = @"TEMPO DISC T/H/D v23";
            [cell.classTagImageView setHidden:NO];
            [cell.classID setHidden:NO];
            [cell.classIDHeadingLabel setHidden:NO];
		}
		else if (device.version.integerValue == 22) {
			cell.labelDeviceIdentifierValue.text = @"TEMPO DISC T/H/D v22";
            [cell.classTagImageView setHidden:YES];
            [cell.classID setHidden:YES];
            [cell.classIDHeadingLabel setHidden:YES];
		}
        else if (device.version.integerValue == 27) {
            cell.labelDeviceIdentifierValue.text = @"PEBBLE v27";
            [cell.classTagImageView setHidden:NO];
            [cell.classID setHidden:NO];
            [cell.classIDHeadingLabel setHidden:NO];
        }
		else if (device.version.integerValue == 13) {
            cell.labelDeviceIdentifierValue.text = @"TEMPO DISC T v13";
            [cell.classTagImageView setHidden:YES];
            [cell.classID setHidden:YES];
            [cell.classIDHeadingLabel setHidden:YES];
		}
		else if (device.version.integerValue == 52) {
			cell.labelDeviceIdentifierValue.text = @"OPEN SENSOR DISC v13";
			[cell.classTagImageView setHidden:YES];
			[cell.classID setHidden:YES];
			[cell.classIDHeadingLabel setHidden:YES];
		}
		else if (device.version.integerValue == 62) {
			cell.labelDeviceIdentifierValue.text = @"LIGHT SENSOR v62";
			[cell.classTagImageView setHidden:YES];
			[cell.classID setHidden:YES];
			[cell.classIDHeadingLabel setHidden:YES];
		}
        else if (device.version.integerValue == 113) {
            cell.labelDeviceIdentifierValue.text = @"TEMPO DISC T BEACON v113";
            [cell.classTagImageView setHidden:YES];
            [cell.classID setHidden:YES];
            [cell.classIDHeadingLabel setHidden:YES];
        }
        
	}
    
}

- (void)fillPressureDeviceCell:(TDPressureDeviceTableViewCell*)cell model:(TDTempoDisc*)device {
	[self fillTempoDiscCell:cell model:device];
	//fill rest of the data
	cell.labelPressureValue.text = device.currentPressure.stringValue;
	cell.dewpointUnits.text = cell.temperatureUnits.text;
    cell.labelCurrentDewPointValue.text = [NSString stringWithFormat:@"%.1fº", [TDHelper temperature:device.dewPoint forDiscDevice:device].floatValue];
}

- (void)fillOtherDeviceCell:(TDOtherDeviceTableViewCell*)cell model:(TDTempoDisc*)device {
	cell.labelDeviceName.text = device.name;
}

- (void)fillTemperatureDeviceCell:(TDTemperatureDeviceTableViewCell*)cell model:(TDTempoDisc*)device {
	[self fillPressureDeviceCell:cell model:device];
	//TODO: Tempo device version 13 data fill
	cell.labelUnitsValue.text = device.isFahrenheit.boolValue ? @"Fahrenheit (˚ K)" : @"Celsius (˚ C)";
	cell.labelModeValue.text = device.mode.stringValue;
	cell.labelThresholdBreachesValue.text = device.numBreach.stringValue;
}

- (void)fillMovemementDeviceCell:(TDMovementDeviceTableViewCell*)cell model:(TDTempoDisc*)device {
	[self fillPressureDeviceCell:cell model:device];
	//TODO: Tempo device version 13 data fill
	cell.labelChannelOneValue.text = device.humSensitivityLevel.stringValue;
	cell.labelChannelTwoValue.text = device.pestSensitivityLevel.stringValue;
	cell.labelPressCountValue.text = device.buttonPressControl.stringValue;
	cell.labelLoggingIntervalValue.text = device.movementMeasurePeriod.stringValue;
	cell.labelIntervalCountValue.text = device.intervalCounter.stringValue;
}

- (void)fillButtonDeviceCell:(TDTemperatureDeviceTableViewCell*)cell model:(TDTempoDisc*)device {
	[self fillPressureDeviceCell:cell model:device];
	//TODO: Tempo device version 42 data fill
	cell.labelTemperatureValue.text = device.buttonPressControl.stringValue;
}

- (void)fillMagnetometerCell:(TDMagnetometerDeviceTableViewCell*)cell model:(TDTempoDisc*)device {
	[self fillTemperatureDeviceCell:cell model:device];
	cell.labelStatusValue.text = device.openCloseStatus ? @"OPEN" : @"CLOSED";
	cell.imageViewStatusBox.image = [UIImage imageNamed:device.openCloseStatus ? @"Green Box" : @"red box"];
}

- (void)fillLuminosityCell:(TDLuminosityDeviceTableViewCell*)cell model:(TDTempoDisc*)device {
	[self fillTemperatureDeviceCell:cell model:device];
	cell.labelLuminosityValue.text = @(device.currentLightLevel.integerValue).stringValue;
}


#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (_sendingData && _indexPathEdit.row == indexPath.row) {
		return;
	}
	self.selectedDevice = _dataSource[indexPath.row];
    [TDSharedDevice sharedDevice].activeDevice = self.selectedDevice;
        
		NSLog(@"Selected device: %@", self.selectedDevice.name);
	if (self.selectedDevice.version.integerValue == 27) {
		[self.parentViewController performSegueWithIdentifier:@"segueTempoDevicePressureInfo" sender:self.selectedDevice];
	}
	else if (self.selectedDevice.version.integerValue == 22 || self.selectedDevice.version.integerValue == 23) {
			[self.parentViewController performSegueWithIdentifier:@"segueTempoDiscDeviceInfo" sender:self.selectedDevice];
	}
	else if (self.selectedDevice.version.integerValue == 13 || self.selectedDevice.version.integerValue == 113) {
		[self.parentViewController performSegueWithIdentifier:@"segueDeviceInfoVersion13" sender:self.selectedDevice];
	}
	else if (self.selectedDevice.version.integerValue == 32) {
		[self.parentViewController performSegueWithIdentifier:@"segueDeviceInfoVersion32" sender:self.selectedDevice];
	}
	else if (self.selectedDevice.version.integerValue == 42) {
		[self.parentViewController performSegueWithIdentifier:@"segueDeviceInfoVersion42" sender:self.selectedDevice];
	}
	else if (self.selectedDevice.version.integerValue == 52) {
		[self.parentViewController performSegueWithIdentifier:@"segueDeviceInfoVersion52" sender:self.selectedDevice];
	}
	else if (self.selectedDevice.version.integerValue == 62) {
		[self.parentViewController performSegueWithIdentifier:@"segueDeviceInfoVersion62" sender:self.selectedDevice];
	}
	else {
		//dont show detail for non tempo disc devices
		[tableView deselectRowAtIndexPath:indexPath animated:YES];
	}
}

- (NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
	__weak typeof(self) weakself = self;
	return @[[UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:NSLocalizedString(@"Blink", nil) handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
		dispatch_async(dispatch_get_main_queue(), ^{
			if (!weakself.sendingData) {
				[weakself.timerUpdateList invalidate];
				weakself.downloader = [[TDUARTAllDataDownloader alloc] init];
				weakself.sendingData = YES;
				weakself.hudBlink = [MBProgressHUD showHUDAddedTo:[weakself.tableView cellForRowAtIndexPath:indexPath] animated:YES];
				weakself.hudBlink.labelText = @"Attempting to blink device...";
				weakself.indexPathEdit = indexPath;
				[weakself.tableView setEditing:NO animated:YES];
				[weakself.downloader writeData:@"*blink" toDevice:_dataSource[indexPath.row] withCompletion:^(BOOL sucess) {
					dispatch_async(dispatch_get_main_queue(), ^{
						weakself.sendingData = NO;
						[weakself scanForDevices];
//						[MBProgressHUD hideAllHUDsForView:weakself.view animated:NO];
						[weakself.hudBlink hide:YES];
						weakself.indexPathEdit = nil;
					});
				}];
			}
		});
	}]];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return _dataSource.count;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	TDTempoDisc *device = _dataSource[indexPath.row];
    NSString *reuse;
	if (([device version].integerValue == 22) || ([device version].integerValue == 23)) {
		reuse = @"cellDevice22and23";
	}
	else if ([device version].integerValue == 27) {
		reuse = @"cellDeviceDisc27";
	}
	else if (([device version].integerValue == 13) || ([device version].integerValue ==113)) {
		reuse = @"cellDevice13";
	}
	else if ([device version].integerValue == 32) {
		reuse = @"cellDevice32";
	}
	else if ([device version].integerValue == 42) {
		reuse = @"cellDevice42";
	}
	else if ([device version].integerValue == 52) {
		reuse = @"cellDevice52";
	}
	else if ([device version].integerValue == 62) {
		reuse = @"cellDevice62";
	}
	else {
		//reuse = @"cellDeviceOther";
	}
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuse forIndexPath:indexPath];
	
	if (_hudBlink.superview == cell && indexPath.row != _indexPathEdit.row) {
		[_hudBlink hide:YES];
	}
	else if (_sendingData && indexPath.row == _indexPathEdit.row && !_hudBlink.superview) {
		_hudBlink = [MBProgressHUD showHUDAddedTo:cell animated:YES];
		_hudBlink.labelText = @"Attempting to blink device...";
	}
	
	cell.backgroundColor = device.globalIdentifier.integerValue == 255 ? [UIColor colorWithWhite:230./255.0 alpha:1.0] : [UIColor whiteColor];
	
	if ([cell isMemberOfClass:[TDMovementDeviceTableViewCell class]]) {
		[self fillMovemementDeviceCell:(TDMovementDeviceTableViewCell*)cell model:device];
	}
	else if ([cell isMemberOfClass:[TDTemperatureDeviceTableViewCell class]]) {
		if (device.version.integerValue == 42) {
			[self fillButtonDeviceCell:(TDTemperatureDeviceTableViewCell*)cell model:device];
		}
		else {
			[self fillTemperatureDeviceCell:(TDTemperatureDeviceTableViewCell*)cell model:device];
		}
	}
	if ([cell isMemberOfClass:[TDPressureDeviceTableViewCell class]]) {
		[self fillPressureDeviceCell:(TDPressureDeviceTableViewCell*)cell model:device];
	}
	else if ([cell isMemberOfClass:[TDDeviceTableViewCell class]]) {
		[self fillTempoDiscCell:(TDDeviceTableViewCell*)cell model:device];
	}
	else if ([cell isMemberOfClass:[TDMagnetometerDeviceTableViewCell class]]) {
		[self fillMagnetometerCell:(TDMagnetometerDeviceTableViewCell*)cell model:device];
	}
	else if ([cell isMemberOfClass:[TDLuminosityDeviceTableViewCell class]]) {
		[self fillLuminosityCell:(TDLuminosityDeviceTableViewCell*)cell model:device];
	}
	else if ([cell isMemberOfClass:[TDOtherDeviceTableViewCell class]]) {
		[self fillOtherDeviceCell:(TDOtherDeviceTableViewCell*)cell model:device];
	}
	
	return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
	TDTempoDisc *device = _dataSource[indexPath.row];
	if (device.version.integerValue == 13 || device.version.integerValue == 113) {
		return 190.;
	}
	else if (device.version.integerValue == 27) {
		return 265.;
	}
	else if (device.version.integerValue == 32) {
		return 210.;
	}
	else if (device.version.integerValue == 42) {
		return 190.;
	}
	else {
		return 190.;
	}
    
}

/**
 *	This is used if cell height calculation (above) is an expensive method that takes too long
 **/
/*- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    
    return 190;
    
}*/




@end
