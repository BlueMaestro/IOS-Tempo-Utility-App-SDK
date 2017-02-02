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
#import <MBProgressHUD/MBProgressHUD.h>
#import "TempoDiscDevice+CoreDataProperties.h"
#import "AppDelegate.h"

#define kDeviceScanInterval 10.0

#define kDeviceListUpdateInterval 5.0
#define kDeviceListUpdateScanInterval 2.0

#define kDeviceOutOfRangeTimer 60.0

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

@end

@implementation TDDeviceListTableViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	[self setupView];
	/**
	 *	Wait until ready to perform scan
	 **/
	if (!_ignoreScan) {
		[[LGCentralManager sharedInstance]
		 addObserver:self forKeyPath:@"centralReady" options:NSKeyValueObservingOptionNew context:nil];
	}
	
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
		[self startScan];
	}
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	if (!_ignoreScan) {
		[self stopScan];
	}
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
	if ([keyPath isEqualToString:@"centralReady"]) {
		if ([LGCentralManager sharedInstance].isCentralReady) {
			dispatch_async(dispatch_get_main_queue(), ^{
				//Bluetooth is ready. Start scan.
				[self scanForDevices];
//				[[LGCentralManager sharedInstance] scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:@"180A"], [CBUUID UUIDWithString:@"180F"]] options:@{CBCentralManagerScanOptionAllowDuplicatesKey : @YES}];
				
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

- (void)startScan {
	if ([self isMemberOfClass:[TDDeviceListTableViewController class]]) {
		if (![LGCentralManager sharedInstance].scanning) {
			[[LGCentralManager sharedInstance] scanForPeripheralsWithServices:nil/*@[[CBUUID UUIDWithString:@"180A"], [CBUUID UUIDWithString:@"180F"]]*/ options:@{CBCentralManagerScanOptionAllowDuplicatesKey : @YES}];
		}
		if (_timerUpdateList) {
			[_timerUpdateList invalidate];
			_timerUpdateList = nil;
		}
		_timerUpdateList = [NSTimer timerWithTimeInterval:kDeviceListUpdateInterval target:self selector:@selector(handleUpdateTimer:) userInfo:nil repeats:YES];
		[[NSRunLoop mainRunLoop] addTimer:_timerUpdateList forMode:NSRunLoopCommonModes];
	}
	
}

- (void)handleUpdateTimer:(NSTimer*)timer {
	__weak typeof(self) weakself = self;
	[[LGCentralManager sharedInstance] scanForPeripheralsByInterval:kDeviceListUpdateScanInterval services:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey : @YES} completion:^(NSArray *peripherals) {
		[weakself updateDeviceList];
	}];
}

- (void)stopScan {
	[[LGCentralManager sharedInstance] stopScanForPeripherals];
	if (_timerUpdateList) {
		[_timerUpdateList invalidate];
		_timerUpdateList = nil;
	}
}

- (void)updateDeviceList {
	_dataSource = [NSMutableArray array];
	for (LGPeripheral *peripheral in [LGCentralManager sharedInstance].peripherals) {
		TempoDevice *device = [self findOrCreateDeviceForPeripheral:peripheral];
		if (device) {
			device.peripheral = peripheral;
		}
	}
	NSFetchRequest *allDeviceFetch = [NSFetchRequest fetchRequestWithEntityName:@"TempoDevice"];
	NSArray *result = [[(AppDelegate*)[UIApplication sharedApplication].delegate managedObjectContext] executeFetchRequest:allDeviceFetch error:nil];
	for (TempoDevice *device in result) {
		device.inRange = @(NO);
		if (device.lastDetected && fabs(device.lastDetected.timeIntervalSinceNow) < kDeviceOutOfRangeTimer) {
			if (_deviceFilterId) {
				//filter by class id enabled
				if ([device classID] == _deviceFilterId.integerValue) {
					device.inRange = @(YES);
					[_dataSource addObject:device];
				}
			}
			else {
				device.inRange = @(YES);
				[_dataSource addObject:device];
			}
		}
	}
	
	//default is by name
	switch (_sortType) {
		case DeviceSortTypeSignalStrength:
			[_dataSource sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"peripheral.RSSI" ascending:YES]]];
			break;
		case DeviceSortTypeClassID:
			[_dataSource sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"classID" ascending:YES]]];
			break;
		default:
			[_dataSource sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES selector:@selector(caseInsensitiveCompare:)]]];
			break;
	}
	[self.tableView reloadData];
}

- (void)scanForDevices {
	//prevent double scan
	if (self.scanning) {
		return;
	}
	//self.scanning = YES;
	//[self stopScan];
	
	//show progress indicator
	/*MBProgressHUD* hud = [MBProgressHUD showHUDAddedTo:self.parentViewController.view animated:YES];
	hud.labelText = NSLocalizedString(@"Scanning...", nil);*/
	
	__weak typeof(self) weakself = self;
	//start scan
	[[LGCentralManager sharedInstance]
	 scanForPeripheralsByInterval:kDeviceScanInterval
	 services:nil/*@[[CBUUID UUIDWithString:@"180A"], [CBUUID UUIDWithString:@"180F"]]*/
	 options:@{CBCentralManagerScanOptionAllowDuplicatesKey : @YES}
	 completion:^(NSArray *peripherals) {
		 //handle scan result
		 
		 //create list of devices
		 /*NSMutableArray *devices = [NSMutableArray array];
		 for (LGPeripheral *peripheral in peripherals) {
			 TempoDevice *device = [self findOrCreateDeviceForPeripheral:peripheral];
			 if (device) {
				 device.peripheral = peripheral;
				 [devices addObject:device];
			 }
		 }
		 
		 _dataSource = devices;
		 [self.tableView reloadData];*/
		 [self updateDeviceList];
		 
		 //cleanup
		 [MBProgressHUD hideAllHUDsForView:self.parentViewController.view animated:NO];
		 weakself.scanning = NO;
		 [self startScan];
	 }];
}

- (TempoDevice*)findOrCreateDeviceForPeripheral:(LGPeripheral*)peripheral {
	/**
	 *	If there is no manufacturer data see if the device is already inserted and return that device.
	 **/
	BOOL hasManufacturerData = [TempoDevice hasManufacturerData:peripheral.advertisingData];
	
	/**
	 *	TDT-2 Non Tempo Disc devices should still be visible, with limited data
	 **/
	BOOL isTempoDiscDevice = [TempoDevice isTempoDiscDeviceWithAdvertisementData:peripheral.advertisingData];
	BOOL isBlueMaestroDevice = [TempoDevice isBlueMaestroDeviceWithAdvertisementData:peripheral.advertisingData];
    BOOL isTempoDisc23 = [TempoDevice isTempoDisc23WithAdvertisementDate:peripheral.advertisingData];
    
    if (isTempoDisc23) {NSLog(@"Found Tempo Disc 23");}
    
	NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([TempoDevice class])];
	request.predicate = [NSPredicate predicateWithFormat:@"self.uuid = %@", peripheral.cbPeripheral.identifier.UUIDString];
	NSError *fetchError;
	NSManagedObjectContext *context = [(AppDelegate*)[UIApplication sharedApplication].delegate managedObjectContext];
	NSArray *result = [context executeFetchRequest:request error:&fetchError];
	
	TempoDevice *device;
	if (!fetchError && result.count > 0) {
		//found existing device
		device = [result firstObject];
		if (isBlueMaestroDevice && hasManufacturerData) {
			[device fillWithData:peripheral.advertisingData name:peripheral.name uuid:peripheral.cbPeripheral.identifier.UUIDString];
		}
		else {
			device.name = peripheral.name;
			device.uuid = peripheral.cbPeripheral.identifier.UUIDString;
		}
		if (hasManufacturerData) {
			device.isBlueMaestroDevice = @(isBlueMaestroDevice);
		}
	}
	else if (!fetchError && hasManufacturerData) {
		//detected new device
		if ((isTempoDiscDevice) || (isTempoDisc23)) {
			device = [TempoDiscDevice deviceWithName:peripheral.name data:peripheral.advertisingData uuid:peripheral.cbPeripheral.identifier.UUIDString context:context];
		}
		else {
			device = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([TempoDevice class]) inManagedObjectContext:context];
			device.name = peripheral.name;
			device.uuid = peripheral.cbPeripheral.identifier.UUIDString;
		}
		device.isBlueMaestroDevice = @(isBlueMaestroDevice);
	}
	else if (hasManufacturerData || fetchError) {
		NSLog(@"Error fetching devices: %@", fetchError.localizedDescription);
	}
	
	NSError *saveError;
	[context save:&saveError];
	if (saveError) {
		NSLog(@"Error saving device named %@: %@", peripheral.name, saveError.localizedDescription);
	}
	
	return device;
}

- (void)handleGoToBackgroundNotifications:(NSNotification*)note {
	if (!_ignoreScan) {
		[self stopScan];
	}
}

- (void)handleReturnToForeground:(NSNotification*)note {
	//reset filters and sort
	_sortType = DeviceSortTypeNone;
	_deviceFilterId = nil;
	[self updateDeviceList];
	
	//resume scanning
	if (!_ignoreScan) {
		[self startScan];
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
			[self.tableView reloadData];
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
	__weak typeof(self) weakself = self;
	
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
}

#pragma mark - Cell fill

- (void)fillTempoDiscCell:(TDDeviceTableViewCell*)cell model:(TempoDevice*)device {
    UIImage *lowBattImage = [UIImage imageNamed:@"battery_low"];
    UIImage *mediumBattImage = [UIImage imageNamed:@"battery_medium"];
    UIImage *highBattImage = [UIImage imageNamed:@"battery_high"];
    UIImage *strongRSSIImage = [UIImage imageNamed:@"rssi_high"];
    UIImage *mediumRSSIImage = [UIImage imageNamed:@"rssi_medium"];
    UIImage *lowRSSIImage = [UIImage imageNamed:@"rssi_low"];
    
    
	cell.labelDeviceName.text = device.name;
	NSString *unit = device.isFahrenheit.boolValue ? @"Fahrenheit" : @"Celsius";
    
    cell.dewpointUnits.text = unit;
    cell.temperatureUnits.text = unit;
	cell.labelTemperatureValue.text = [NSString stringWithFormat:@"%.1fº", [TDHelper temperature:device.currentTemperature forDevice:device].floatValue];
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
		cell.labelDeviceVersionValue.text = device.version;
	}
	else {
		cell.labelDeviceVersion.text = NSLocalizedString(@"No version info", nil);
		cell.labelDeviceVersionValue.hidden = YES;
	}
	cell.labelDeviceRSSIValue.text = [NSString stringWithFormat:@"%ddB", device.peripheral.RSSI];
    
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
	if ([device isKindOfClass:[TempoDiscDevice class]]) {
		TempoDiscDevice* disc = (TempoDiscDevice*)device;
		cell.labelCurrentDewPointValue.text = [NSString stringWithFormat:@"%.1fº", [TDHelper temperature:disc.dewPoint forDevice:device].floatValue];
		if (device.version.integerValue == 23) {
			cell.labelDeviceIdentifierValue.text = @"TEMPO DISC T/H/D v23";
		}
		else if (device.version.integerValue == 22) {
			cell.labelDeviceIdentifierValue.text = @"TEMPO DISC T/H/D v22";
		}
	} else {
		cell.labelCurrentDewPointValue.text = @"0";
	}
    
}

- (void)fillOtherDeviceCell:(TDOtherDeviceTableViewCell*)cell model:(TempoDevice*)device {
	cell.labelDeviceName.text = device.name;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	TempoDevice *selectedDevice = _dataSource[indexPath.row];
//	if (selectedDevice.isTempoDiscDevice.boolValue) {
		//Selected device is tempo disc. Set global singleton reference and go to details
		[TDDefaultDevice sharedDevice].selectedDevice = selectedDevice;
		NSLog(@"Selected device: %@", selectedDevice.name);
	if (!selectedDevice.inRange.boolValue) {
		[self.parentViewController.navigationController pushViewController:[self.storyboard instantiateViewControllerWithIdentifier:@"viewControllerGraph"] animated:YES];
	}
	else if ([selectedDevice isKindOfClass:[TempoDiscDevice class]]) {
		[self.parentViewController performSegueWithIdentifier:@"segueTempoDiscDeviceInfo" sender:selectedDevice];
	}
	else {
		[self.parentViewController performSegueWithIdentifier:@"segueDeviceInfo" sender:selectedDevice];
	}
	/*}
	else {
		//dont show detail for non tempo disc devices
		[tableView deselectRowAtIndexPath:indexPath animated:YES];
	}*/
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return _dataSource.count;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	TempoDevice *device = _dataSource[indexPath.row];
	
	NSString *reuse = @"";
	if (device.isBlueMaestroDevice.boolValue) {
		reuse = @"cellDeviceTempoDisc";
	}
	else {
		reuse = @"cellDeviceOther";
	}
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuse forIndexPath:indexPath];
	
	if ([cell isKindOfClass:[TDDeviceTableViewCell class]]) {
		[self fillTempoDiscCell:(TDDeviceTableViewCell*)cell model:device];
	}
	else if ([cell isKindOfClass:[TDOtherDeviceTableViewCell class]]) {
		[self fillOtherDeviceCell:(TDOtherDeviceTableViewCell*)cell model:device];
	}
	
	return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	TempoDevice *device = _dataSource[indexPath.row];
	
	return device.isBlueMaestroDevice.boolValue ? 180 : 97;
}

@end
