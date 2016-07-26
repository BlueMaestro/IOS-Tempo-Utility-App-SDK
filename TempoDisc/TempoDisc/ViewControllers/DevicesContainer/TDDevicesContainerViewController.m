//
//  TDDevicesContainerViewController.m
//  TempoDisc
//
//  Created by Nikola Misic on 7/26/16.
//  Copyright © 2016 BlueMaestro. All rights reserved.
//

#import "TDDevicesContainerViewController.h"

@implementation TDDevicesContainerViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	[self setupView];
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
}
@end
