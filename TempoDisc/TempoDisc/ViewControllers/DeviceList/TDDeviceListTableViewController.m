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
#import <MBProgressHUD/MBProgressHUD.h>
#import "TempoDevice.h"
#import "AppDelegate.h"

@interface TDDeviceListTableViewController()

@property (nonatomic, strong) NSArray *dataSource;

@end

@implementation TDDeviceListTableViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	[self setupView];
	/**
	 *	Wait until ready to perform scan
	 **/
	MBProgressHUD* hud = [MBProgressHUD showHUDAddedTo:self.parentViewController.view animated:YES];
	hud.labelText = NSLocalizedString(@"Scanning...", nil);
	[[LGCentralManager sharedInstance] addObserver:self forKeyPath:@"centralReady" options:NSKeyValueObservingOptionNew context:nil];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
	if ([keyPath isEqualToString:@"centralReady"]) {
		if ([LGCentralManager sharedInstance].isCentralReady) {
			dispatch_async(dispatch_get_main_queue(), ^{
				[self scanForDevices];
				[[LGCentralManager sharedInstance] removeObserver:self forKeyPath:@"centralReady"];
			});
		}
	}
}

#pragma mark - Private methods

- (void)setupView {
	self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
	UIRefreshControl *control = [[UIRefreshControl alloc] init];
	[control addTarget:self action:@selector(handlePullRefresh:) forControlEvents:UIControlEventValueChanged];
	self.refreshControl = control;
}

- (void)handlePullRefresh:(UIRefreshControl*)refreshControl {
	if (refreshControl.isRefreshing) {
		[self scanForDevices];
	}
}

- (void)scanForDevices {
	[[LGCentralManager sharedInstance]
	 scanForPeripheralsByInterval:2
	 services:@[[CBUUID UUIDWithString:@"180A"], [CBUUID UUIDWithString:@"180F"]]
	 options:@{CBCentralManagerScanOptionAllowDuplicatesKey : @YES}
	 completion:^(NSArray *peripherals) {
		 NSMutableArray *devices = [NSMutableArray array];
		 for (LGPeripheral *peripheral in peripherals) {
			 TempoDevice *device = [self findOrCreateDeviceForPeripheral:peripheral];
			 if (device) {
				 [devices addObject:device];
			 }
		 }
		 _dataSource = devices;
		 [self.refreshControl endRefreshing];
		 [self.tableView reloadData];
		 [MBProgressHUD hideAllHUDsForView:self.parentViewController.view animated:NO];
	 }];
	
	/*[[LGCentralManager sharedInstance] scanForPeripheralsByInterval:2 completion:^(NSArray *peripherals) {
		_dataSource = peripherals;
		[self.tableView reloadData];
	}];*/
}

- (TempoDevice*)findOrCreateDeviceForPeripheral:(LGPeripheral*)peripheral {
	NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([TempoDevice class])];
	request.predicate = [NSPredicate predicateWithFormat:@"self.uuid = %@", peripheral.cbPeripheral.identifier.UUIDString];
	NSError *fetchError;
	NSManagedObjectContext *context = [(AppDelegate*)[UIApplication sharedApplication].delegate managedObjectContext];
	NSArray *result = [context executeFetchRequest:request error:&fetchError];
	
	TempoDevice *device;
	if (!fetchError && result.count > 0) {
		device = [result firstObject];
		[device fillWithData:peripheral.advertisingData name:peripheral.name uuid:peripheral.cbPeripheral.identifier.UUIDString];
	}
	else if (!fetchError) {
		device = [TempoDevice deviceWithName:peripheral.name data:peripheral.advertisingData uuid:peripheral.cbPeripheral.identifier.UUIDString context:context];
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

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	TempoDevice *selectedDevice = _dataSource[indexPath.row];
	[TDDefaultDevice sharedDevice].selectedDevice = selectedDevice;
	NSLog(@"Selected device: %@", selectedDevice.name);
	[self performSegueWithIdentifier:@"segueDeviceInfo" sender:selectedDevice];
	
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return _dataSource.count;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	TDDeviceTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cellDevice" forIndexPath:indexPath];
	
	TempoDevice *device = _dataSource[indexPath.row];
	
	cell.labelDeviceName.text = device.name;
	cell.labelTemperatureValue.text = [NSString stringWithFormat:@"%.1f", device.currentTemperature.floatValue];
	cell.labelHumidityValue.text = [NSString stringWithFormat:@"%ld%%", (long)device.currentHumidity.integerValue];
	
	return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 94;
}


@end
