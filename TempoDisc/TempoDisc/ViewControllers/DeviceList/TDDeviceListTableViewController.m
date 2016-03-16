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
#import "TempoDevice.h"
#import "AppDelegate.h"

#define kDeviceScanInterval 5.0

#define kDeviceListUpdateInterval 1.0

@interface TDDeviceListTableViewController()

@property (nonatomic, strong) NSMutableArray *dataSource;
@property (nonatomic, assign) BOOL scanning;

@property (nonatomic, strong) NSTimer *timerUpdateList;

@end

@implementation TDDeviceListTableViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	[self setupView];
	/**
	 *	Wait until ready to perform scan
	 **/
	[[LGCentralManager sharedInstance]
	 addObserver:self forKeyPath:@"centralReady" options:NSKeyValueObservingOptionNew context:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleGoToBackgroundNotifications:) name:UIApplicationWillResignActiveNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleReturnToForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	[self startScan];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	[self stopScan];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
	if ([keyPath isEqualToString:@"centralReady"]) {
		if ([LGCentralManager sharedInstance].isCentralReady) {
			dispatch_async(dispatch_get_main_queue(), ^{
				//Bluetooth is ready. Start scan.
//				[self scanForDevices];
				[[LGCentralManager sharedInstance] scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:@"180A"], [CBUUID UUIDWithString:@"180F"]] options:@{CBCentralManagerScanOptionAllowDuplicatesKey : @YES}];
				
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
	if (![LGCentralManager sharedInstance].scanning) {
		[[LGCentralManager sharedInstance] scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:@"180A"], [CBUUID UUIDWithString:@"180F"]] options:@{CBCentralManagerScanOptionAllowDuplicatesKey : @YES}];
	}
	if (_timerUpdateList) {
		[_timerUpdateList invalidate];
		_timerUpdateList = nil;
	}
	_timerUpdateList = [NSTimer timerWithTimeInterval:kDeviceListUpdateInterval target:self selector:@selector(updateDeviceList) userInfo:nil repeats:YES];
	[[NSRunLoop mainRunLoop] addTimer:_timerUpdateList forMode:NSRunLoopCommonModes];
}

- (void)stopScan {
	[[LGCentralManager sharedInstance] stopScanForPeripherals];
	if (_timerUpdateList) {
		[_timerUpdateList invalidate];
		_timerUpdateList = nil;
	}
}

- (void)updateDeviceList {
	NSMutableArray *devicesInRange = [NSMutableArray array];
	NSMutableArray *devicesOutOfRange = [NSMutableArray array];
	if (!_dataSource) {
		_dataSource = [NSMutableArray array];
	}
	for (LGPeripheral *peripheral in [LGCentralManager sharedInstance].peripherals) {
		TempoDevice *device = [self findOrCreateDeviceForPeripheral:peripheral];
		if (device) {
			device.peripheral = peripheral;
			[devicesInRange addObject:device];
			if (![[_dataSource valueForKey:@"uuid"] containsObject:device.uuid]) {
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
	if (_scanning) {
		return;
	}
	_scanning = YES;
	
	//show progress indicator
	MBProgressHUD* hud = [MBProgressHUD showHUDAddedTo:self.parentViewController.view animated:YES];
	hud.labelText = NSLocalizedString(@"Scanning...", nil);
	
	//start scan
	[[LGCentralManager sharedInstance]
	 scanForPeripheralsByInterval:kDeviceScanInterval
	 services:@[[CBUUID UUIDWithString:@"180A"], [CBUUID UUIDWithString:@"180F"]]
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
		 _scanning = NO;
	 }];
}

- (TempoDevice*)findOrCreateDeviceForPeripheral:(LGPeripheral*)peripheral {
	/**
	 *	TDT-2 Non Tempo Disc devices should still be visible, with limited data
	 **/
	BOOL isTempoDiscDevice = [TempoDevice isTempoDiscDeviceWithAdvertisementData:peripheral.advertisingData];
	
	NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([TempoDevice class])];
	request.predicate = [NSPredicate predicateWithFormat:@"self.uuid = %@", peripheral.cbPeripheral.identifier.UUIDString];
	NSError *fetchError;
	NSManagedObjectContext *context = [(AppDelegate*)[UIApplication sharedApplication].delegate managedObjectContext];
	NSArray *result = [context executeFetchRequest:request error:&fetchError];
	
	TempoDevice *device;
	if (!fetchError && result.count > 0) {
		//found existing device
		device = [result firstObject];
		if (isTempoDiscDevice) {
			[device fillWithData:peripheral.advertisingData name:peripheral.name uuid:peripheral.cbPeripheral.identifier.UUIDString];
		}
		else {
			device.name = peripheral.name;
			device.uuid = peripheral.cbPeripheral.identifier.UUIDString;
		}
		device.isTempoDiscDevice = @(isTempoDiscDevice);
	}
	else if (!fetchError) {
		//detected new device
		if (isTempoDiscDevice) {
			device = [TempoDevice deviceWithName:peripheral.name data:peripheral.advertisingData uuid:peripheral.cbPeripheral.identifier.UUIDString context:context];
		}
		else {
			device = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([TempoDevice class]) inManagedObjectContext:context];
			device.name = peripheral.name;
			device.uuid = peripheral.cbPeripheral.identifier.UUIDString;
		}
		device.isTempoDiscDevice = @(isTempoDiscDevice);
	}
	else {
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
	[self stopScan];
}

- (void)handleReturnToForeground:(NSNotification*)note {
	[self startScan];
}

#pragma mark - Actions

- (IBAction)buttonScanClicked:(UIBarButtonItem*)sender {
	[self scanForDevices];
}

#pragma mark - Cell fill

- (void)fillTempoDiscCell:(TDDeviceTableViewCell*)cell model:(TempoDevice*)device {
	cell.labelDeviceName.text = device.name;
	cell.labelTemperatureValue.text = [NSString stringWithFormat:@"%.1f˚%@", [TDHelper temperature:device.currentTemperature forDevice:device].floatValue, device.isFahrenheit.boolValue ? @"F" : @"C"];
	cell.labelHumidityValue.text = [NSString stringWithFormat:@"%ld%%", (long)device.currentHumidity.integerValue];
	if (device.battery.integerValue > 0) {
		cell.labelDeviceBattery.text = [NSString stringWithFormat:NSLocalizedString(@"Battery: %@%%", nil), device.battery.stringValue];
	}
	else {
		cell.labelDeviceBattery.text = NSLocalizedString(@"No Battery info", nil);
	}
	if (device.version) {
		cell.labelDeviceVersion.text = [NSString stringWithFormat:NSLocalizedString(@"Version: %@", nil), device.version];
	}
	else {
		cell.labelDeviceVersion.text = NSLocalizedString(@"No version info", nil);
	}
	cell.labelRSSIValue.text = [NSString stringWithFormat:NSLocalizedString(@"RSSI: %ld", nil), device.peripheral.RSSI];
}

- (void)fillOtherDeviceCell:(TDOtherDeviceTableViewCell*)cell model:(TempoDevice*)device {
	cell.labelDeviceName.text = device.name;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	TempoDevice *selectedDevice = _dataSource[indexPath.row];
	if (selectedDevice.isTempoDiscDevice.boolValue) {
		//Selected device is tempo disc. Set global singleton reference and go to details
		[TDDefaultDevice sharedDevice].selectedDevice = selectedDevice;
		NSLog(@"Selected device: %@", selectedDevice.name);
		[self performSegueWithIdentifier:@"segueDeviceInfo" sender:selectedDevice];
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
	TempoDevice *device = _dataSource[indexPath.row];
	
	NSString *reuse = @"";
	if (device.isTempoDiscDevice.boolValue) {
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
	return 94;
}


@end
