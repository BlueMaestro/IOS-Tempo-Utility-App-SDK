//
//  TDDevicePressureInfoViewController.m
//  Tempo Utility
//
//  Created by Nikola Misic on 2/15/17.
//  Copyright © 2017 BlueMaestro. All rights reserved.
//

#import "TDDevicePressureInfoViewController.h"
#import "TempoDiscDevice+CoreDataProperties.h"

@interface TDDevicePressureInfoViewController ()

@end

@implementation TDDevicePressureInfoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	float startValue = _constraintInfoContainerHeight.constant;
	float difference = 736-[UIScreen mainScreen].bounds.size.height;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Public methods

- (void)fillData {
	[super fillData];
	TempoDiscDevice *device = (TempoDiscDevice*)[TDSharedDevice sharedDevice].selectedDevice;
	_labelPressureCurrentValue.text = @"1016.6 hPa";//device.currentPressure.stringValue;
	_labelPressureHighestDayLogged.text = @"1016.7 hPa";//device.highestDayPressure.stringValue;
	_labelPressureAverageDayLogged.text = @"1014.6 hPa";//device.averageDayPressure.stringValue;
	_labelPressureLowestDayLogged.text = @"1014.0 hPa";//device.lowestDayPressure.stringValue;
}

@end
