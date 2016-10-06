//
//  TDDevicesContainerViewController.m
//  TempoDisc
//
//  Created by Nikola Misic on 7/26/16.
//  Copyright © 2016 BlueMaestro. All rights reserved.
//

#import "TDDevicesContainerViewController.h"

@interface TDDevicesContainerViewController()

@end

@implementation TDDevicesContainerViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	[self setupView];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.destinationViewController isKindOfClass:[TDDeviceListTableViewController class]]) {
		_controllerDeviceList = segue.destinationViewController;
		//setup KVO to change scanning label text
		[_controllerDeviceList addObserver:self forKeyPath:@"scanning" options:NSKeyValueObservingOptionNew context:NULL];
	}
}

- (void)dealloc {
	[_controllerDeviceList removeObserver:self forKeyPath:@"scanning"];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
	if ([object isEqual:_controllerDeviceList]) {
		_labelScanStatus.text = _controllerDeviceList.scanning ? NSLocalizedString(@"Currently Scanning......", nil) : NSLocalizedString(@"Not scanning", nil);
	}
}

#pragma mark - Private methods

- (void)setupView {
	[super setupView];
	UIBarButtonItem *itemScan = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Scan", nil) style:UIBarButtonItemStyleDone target:self action:@selector(buttonStartScanClicked:)];
	self.navigationItem.rightBarButtonItem = itemScan;
	
	UIBarButtonItem *itemHistory = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"History", nil) style:UIBarButtonItemStyleDone target:self action:@selector(buttonHistoryClicked:)];
	self.navigationItem.leftBarButtonItem = itemHistory;
}

#pragma mark - Actions

- (IBAction)buttonStartScanClicked:(UIButton *)sender {
	[_controllerDeviceList scanForDevices];
}

- (IBAction)buttonHistoryClicked:(UIButton *)sender {
	[self performSegueWithIdentifier:@"segueHistory" sender:nil];
}
@end
