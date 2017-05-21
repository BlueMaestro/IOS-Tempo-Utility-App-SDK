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

@end

@implementation TDDeviceListTableViewController

- (void)viewDidLoad {
	[super viewDidLoad];
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
		 NSArray *sorted = [devices sortedArrayUsingDescriptors:sortDescriptors];
		 
		 weakself.dataSource = [sorted mutableCopy];
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
    
    
    if ([device isKindOfClass:[TDTempoDisc class]]) {
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
    

    cell.dewpointUnits.text = unit;
    cell.temperatureUnits.text = unit;
	cell.labelTemperatureValue.text = [NSString stringWithFormat:@"%.1fº", [TDHelper temperature:device.currentTemperature forDiscDevice:device].floatValue];
	cell.labelHumidityValue.text = [NSString stringWithFormat:@"%ld%%", (long)device.currentHumidity.integerValue];
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
    
	
	cell.labelDeviceUUIDValue.text = [NSString stringWithFormat:@"%@", device.peripheral.UUIDString];
	
	cell.labelDeviceIdentifierValue.text = @"OTHER TEMPO DISC";
	if ([device isKindOfClass:[TDTempoDisc class]]) {
		TDTempoDisc* disc = (TDTempoDisc*)device;
		cell.labelCurrentDewPointValue.text = [NSString stringWithFormat:@"%.1fº", [TDHelper temperature:disc.dewPoint forDiscDevice:device].floatValue];
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
            [cell.classTagImageView setHidden:YES];
            [cell.classID setHidden:YES];
            [cell.classIDHeadingLabel setHidden:YES];
        }
		else if (device.version.integerValue == 13) {
            cell.labelDeviceIdentifierValue.text = @"TEMPO DISC T v13";
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
        
	} else {
		cell.labelCurrentDewPointValue.text = @"0";
	}
    
}

- (void)fillPressureDeviceCell:(TDPressureDeviceTableViewCell*)cell model:(TDTempoDisc*)device {
	//fill rest of the data
	cell.labelPressureValue.text = device.currentPressure.stringValue;
	cell.dewpointUnits.text = cell.temperatureUnits.text;
    cell.labelCurrentDewPointValue.text = device.dewPoint.stringValue;
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


#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	self.selectedDevice = _dataSource[indexPath.row];
    [TDSharedDevice sharedDevice].activeDevice = self.selectedDevice;
        
		NSLog(@"Selected device: %@", self.selectedDevice.name);
	if (self.selectedDevice.version.integerValue == 27) {
		[self.parentViewController performSegueWithIdentifier:@"segueTempoDevicePressureInfo" sender:self.selectedDevice];
	}
	else if (self.selectedDevice.version.integerValue == 22 || self.selectedDevice.version.integerValue == 23) {
			[self.parentViewController performSegueWithIdentifier:@"segueTempoDiscDeviceInfo" sender:self.selectedDevice];
	}
	else if (self.selectedDevice.version.integerValue == 13) {
		[self.parentViewController performSegueWithIdentifier:@"segueDeviceInfoVersion13" sender:self.selectedDevice];
	}
	else if (self.selectedDevice.version.integerValue == 32) {
		[self.parentViewController performSegueWithIdentifier:@"segueDeviceInfoVersion32" sender:self.selectedDevice];
	}
	else {
		//dont show detail for non tempo disc devices
		[tableView deselectRowAtIndexPath:indexPath animated:YES];
	}
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
	else {
		//reuse = @"cellDeviceOther";
	}
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuse forIndexPath:indexPath];
	
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
	else if ([cell isMemberOfClass:[TDOtherDeviceTableViewCell class]]) {
		[self fillOtherDeviceCell:(TDOtherDeviceTableViewCell*)cell model:device];
	}
	
	return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
	TDTempoDisc *device = _dataSource[indexPath.row];
	if (device.version.integerValue == 13) {
		return 150.;
	}
	else if (device.version.integerValue == 27) {
		return 265.;
	}
	else if (device.version.integerValue == 32) {
		return 134.;
	}
	else if (device.version.integerValue == 42) {
		return 120.;
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
