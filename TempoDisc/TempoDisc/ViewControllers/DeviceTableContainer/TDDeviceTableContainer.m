//
//  TDDeviceTableContainer.m
//  TempoDisc
//
//  Created by Nikola Misic on 7/26/16.
//  Copyright © 2016 BlueMaestro. All rights reserved.
//

#import "TDDeviceTableContainer.h"
#import "TDDeviceDataTableViewController.h"

@interface TDDeviceTableContainer()

@property (nonatomic, strong) TDDeviceDataTableViewController *controllerDeviceTable;

@end

@implementation TDDeviceTableContainer

- (void)viewDidLoad {
	[super viewDidLoad];
	[self setupView];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.destinationViewController isKindOfClass:[TDDeviceDataTableViewController class]]) {
		_controllerDeviceTable = segue.destinationViewController;
	}
}

#pragma mark - Private methods

- (void)setupView {
	for (UIButton *button in _buttonsBottomMenu) {
		button.layer.cornerRadius = 8.0;
		button.clipsToBounds = YES;
		button.layer.borderWidth = 2;
		button.layer.borderColor = [UIColor blueMaestroBlue].CGColor;
		[button setBackgroundImage:[[SCHelper imageWithColor:button.backgroundColor] resizableImageWithCapInsets:UIEdgeInsetsZero]  forState:UIControlStateNormal];
		[button setBackgroundImage:[[SCHelper imageWithColor:[UIColor blueMaestroBlue]] resizableImageWithCapInsets:UIEdgeInsetsZero]  forState:UIControlStateHighlighted];
		[button setBackgroundImage:[[SCHelper imageWithColor:[UIColor blueMaestroBlue]] resizableImageWithCapInsets:UIEdgeInsetsZero]  forState:UIControlStateSelected];
		[button setTitleColor:[UIColor blueMaestroBlue] forState:UIControlStateNormal];
		[button setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
		[button setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
		button.titleLabel.numberOfLines = 2;
		button.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
		button.titleLabel.textAlignment = NSTextAlignmentCenter;
	}
	_viewBottomMenuContainer.layer.borderColor = [UIColor botomBarSeparatorGrey].CGColor;
	_viewBottomMenuContainer.layer.borderWidth = 1;
}

#pragma mark - Actions

- (IBAction)buttonExportPdfClicked:(UIButton *)sender {
}

- (IBAction)buttonExportCSVClicked:(UIButton *)sender {
}

- (IBAction)buttonChangeReadingTypeClicked:(UIButton *)sender {
	[_controllerDeviceTable changeReadingType];
	[_buttonReadingType setTitle:(_controllerDeviceTable.currentReadingType == TempoReadingTypeTemperature) ? @"Temperature data" : @"Humidity data" forState:UIControlStateNormal];
	[_buttonReadingType setTitle:(_controllerDeviceTable.currentReadingType == TempoReadingTypeTemperature) ? @"Temperature data" : @"Humidity data" forState:UIControlStateSelected];
	[_buttonReadingType setTitle:(_controllerDeviceTable.currentReadingType == TempoReadingTypeTemperature) ? @"Temperature data" : @"Humidity data" forState:UIControlStateHighlighted];
}
@end
