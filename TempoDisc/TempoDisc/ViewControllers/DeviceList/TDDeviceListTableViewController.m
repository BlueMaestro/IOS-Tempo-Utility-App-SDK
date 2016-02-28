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

#define MANUF_ID_BLUE_MAESTRO 0x0133
#define BM_MODEL_T30 0
#define BM_MODEL_THP 1

int getInt(char lsb,char msb)
{
	return (((int) lsb) & 0xFF) | (((int) msb) << 8);
}

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
}

- (void)scanForDevices {
	[[LGCentralManager sharedInstance]
	 scanForPeripheralsByInterval:2
	 services:@[[CBUUID UUIDWithString:@"180A"], [CBUUID UUIDWithString:@"180F"]]
	 options:@{CBCentralManagerScanOptionAllowDuplicatesKey : @YES}
	 completion:^(NSArray *peripherals) {
		 _dataSource = peripherals;
		 [self.tableView reloadData];
		 [MBProgressHUD hideAllHUDsForView:self.parentViewController.view animated:NO];
	 }];
	
	/*[[LGCentralManager sharedInstance] scanForPeripheralsByInterval:2 completion:^(NSArray *peripherals) {
		_dataSource = peripherals;
		[self.tableView reloadData];
	}];*/
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	LGPeripheral *selectedDevice = _dataSource[indexPath.row];
	NSLog(@"Selected device: %@", selectedDevice.name);
	
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return _dataSource.count;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	TDDeviceTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cellDevice" forIndexPath:indexPath];
	
	LGPeripheral *device = _dataSource[indexPath.row];
	
	cell.labelDeviceName.text = device.name;
	
	NSData *custom = [device.advertisingData objectForKey:@"kCBAdvDataManufacturerData"];
	
	bool isTempoLegacy =  (custom == nil && [device.name isEqualToString:@"Tempo "]);
	bool isTempoT30 = false;
	bool isTempoTHP = false;
	NSString *deviceType = nil;
	
	//BlueMaestro device
	if (custom != nil)
	{
		unsigned char * d = (unsigned char*)[custom bytes];
		unsigned int manuf = d[1] << 8 | d[0];
		
		//Is this one of ours?
		if (manuf == MANUF_ID_BLUE_MAESTRO) {
			if (d[2] == BM_MODEL_T30) {
				deviceType = @"TEMPO_T30";
				isTempoT30 = true;
			} else if (d[2] == BM_MODEL_THP) {
				deviceType = @"TEMPO_THP";
				isTempoTHP = true;
			}
		}
	}
	else {
		//device is legacy
		deviceType = @"TEMPO_LEGACY";
	}
	
	char * data = (char*)[custom bytes];
	float min = getInt(data[3],data[4]) / 10.0f;
	float avg = getInt(data[5],data[6]) / 10.0f;
	float max = getInt(data[7],data[8]) / 10.0f;
	
	cell.labelTemperatureValue.text = [NSString stringWithFormat:@"%.1f", avg];
	
	if (isTempoTHP) {
		int humidity = data[9];
		int pressure = getInt(data[10],data[11]);
		int pressureDelta = getInt(data[12],data[13]);
		cell.labelHumidityValue.text = [NSString stringWithFormat:@"%ld%%", (long)humidity];
	}
	
	return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 94;
}


@end
