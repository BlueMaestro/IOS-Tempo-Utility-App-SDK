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
	[super setupView];
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

- (void)adjustedButtonTitles {
	NSString *title = @"";
	switch (_controllerDeviceTable.currentReadingType) {
		case TempoReadingTypeTemperature:
			title = @"Temperature data";
			break;
		case TempoReadingTypeHumidity:
			title = @"Humidity data";
			break;
		case TempoReadingTypeDewPoint:
			title = @"Dew point data";
			break;
			
  default:
			break;
	}
	[_buttonReadingType setTitle:title forState:UIControlStateNormal];
	[_buttonReadingType setTitle:title forState:UIControlStateSelected];
	[_buttonReadingType setTitle:title forState:UIControlStateHighlighted];
}

#pragma mark - Actions

- (IBAction)buttonExportPdfClicked:(UIButton *)sender {
}

- (IBAction)buttonExportCSVClicked:(UIButton *)sender {
}

- (IBAction)buttonChangeReadingTypeClicked:(UIButton *)sender {
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"READING TYPE", nil) message:NSLocalizedString(@"Choose reading type", nil) preferredStyle:UIAlertControllerStyleActionSheet];
	__weak typeof(self) weakself = self;
	[alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Temperature", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
		[weakself.controllerDeviceTable changeReadingType:TempoReadingTypeTemperature];
		[weakself adjustedButtonTitles];
	}]];
	[alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Humidity", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
		[weakself.controllerDeviceTable changeReadingType:TempoReadingTypeHumidity];
		[weakself adjustedButtonTitles];
	}]];
	[alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Dew Point", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
		[weakself.controllerDeviceTable changeReadingType:TempoReadingTypeDewPoint];
		[weakself adjustedButtonTitles];
	}]];
	[alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil]];
	[self presentViewController:alert animated:YES completion:nil];
}
@end
