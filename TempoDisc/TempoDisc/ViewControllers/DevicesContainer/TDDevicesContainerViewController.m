//
//  TDDevicesContainerViewController.m
//  TempoDisc
//
//  Created by Nikola Misic on 7/26/16.
//  Copyright © 2016 BlueMaestro. All rights reserved.
//

#import "TDDevicesContainerViewController.h"
#import "TDDeviceListTableViewController.h"

@interface TDDevicesContainerViewController()

@property (nonatomic, strong) TDDeviceListTableViewController *controllerDeviceList;

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
	_buttonStartScan.layer.cornerRadius = 8.0;
	_buttonStartScan.clipsToBounds = YES;
	_buttonStartScan.layer.borderWidth = 2.0;
	_buttonStartScan.layer.borderColor = [_buttonStartScan titleColorForState:UIControlStateNormal].CGColor;
}

#pragma mark - Actions

- (IBAction)buttonStartScanClicked:(UIButton *)sender {
	[_controllerDeviceList scanForDevices];
}
@end
