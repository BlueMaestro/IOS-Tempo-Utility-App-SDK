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

#define kDeviceScanInterval 5.0

#define kDeviceListUpdateInterval 3.0
#define kDeviceListUpdateScanInterval 2.0

@interface TDDeviceListTableViewController()

@property (nonatomic, strong) NSTimer *timerUpdateList;

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
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"scan"] style:UIBarButtonItemStyleDone target:self action:@selector(buttonScanClicked:)];
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
	NSFetchRequest *allDeviceFetch = [NSFetchRequest fetchRequestWithEntityName:@"TempoDevice"];
	NSArray *result = [[(AppDelegate*)[UIApplication sharedApplication].delegate managedObjectContext] executeFetchRequest:allDeviceFetch error:nil];
	for (TempoDevice *device in result) {
		device.inRange = @(NO);
	}
	
	NSMutableArray *devicesInRange = [NSMutableArray array];
	NSMutableArray *devicesOutOfRange = [NSMutableArray array];
	if (!_dataSource) {
		_dataSource = [NSMutableArray array];
	}
	for (LGPeripheral *peripheral in [LGCentralManager sharedInstance].peripherals) {
		TempoDevice *device = [self findOrCreateDeviceForPeripheral:peripheral];
		if (device) {
			device.peripheral = peripheral;
			device.inRange = @(YES);
			[devicesInRange addObject:device];
			NSInteger index = [[_dataSource valueForKey:@"uuid"] indexOfObject:device.uuid];
			if (index < _dataSource.count) {
				[_dataSource replaceObjectAtIndex:index withObject:device];
			}
			else {
				[_dataSource addObject:device];
			}
		}
	}
	for (TempoDevice *device in _dataSource) {
		if (![[devicesInRange valueForKey:@"uuid"] containsObject:device.uuid]) {
			[devicesOutOfRange addObject:device];
		}
	}
	[_dataSource removeObjectsInArray:devicesOutOfRange];
	[self.tableView reloadData];
}

- (void)scanForDevices {
	//prevent double scan
	if (self.scanning) {
		return;
	}
	self.scanning = YES;
	[self stopScan];
	
	//show progress indicator
	MBProgressHUD* hud = [MBProgressHUD showHUDAddedTo:self.parentViewController.view animated:YES];
	hud.labelText = NSLocalizedString(@"Scanning...", nil);
	
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
		if (isTempoDiscDevice) {
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
	[self scanForDevices];
}

#pragma mark - Cell fill

- (void)fillTempoDiscCell:(TDDeviceTableViewCell*)cell model:(TempoDevice*)device {
	cell.labelDeviceName.text = device.name;
	NSString *unit = device.isFahrenheit.boolValue ? @"Fahrenheit" : @"Celsius";
	if ([device isKindOfClass:[TempoDiscDevice class]]) {
		cell.labelTemperatureValue.text = [NSString stringWithFormat:@"%.1f˚ %@", device.currentTemperature.floatValue, unit];
	}
	else {
		cell.labelTemperatureValue.text = [NSString stringWithFormat:@"%.1f˚ %@", [TDHelper temperature:device.currentTemperature forDevice:device].floatValue, unit];
	}
	cell.labelHumidityValue.text = [NSString stringWithFormat:@"%ld%% RH", (long)device.currentHumidity.integerValue];
	cell.labelDeviceBatteryValue.text = [NSString stringWithFormat:@"%@%%", device.battery.stringValue];
	
	if (device.version) {
		cell.labelDeviceVersion.text = [NSString stringWithFormat:NSLocalizedString(@"Version:", nil)];
		cell.labelDeviceVersionValue.hidden = NO;
		cell.labelDeviceVersionValue.text = device.version;
	}
	else {
		cell.labelDeviceVersion.text = NSLocalizedString(@"No version info", nil);
		cell.labelDeviceVersionValue.hidden = YES;
	}
	cell.labelDeviceRSSIValue.text = [NSString stringWithFormat:@"%ld dBm", device.peripheral.RSSI];
	
	cell.labelDeviceUUIDValue.text = [NSString stringWithFormat:@"%@", device.peripheral.UUIDString];
	
	if ([device isKindOfClass:[TempoDiscDevice class]]) {
		TempoDiscDevice* disc = (TempoDiscDevice*)device;
		cell.labelCurrentDewPointValue.text = [NSString stringWithFormat:@"%.1f˚ %@", [TDHelper temperature:disc.dewPoint forDevice:device].floatValue, device.isFahrenheit.boolValue ? @"Fahrenheit" : @"Celsius"];
	}
	else {
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
