//
//  TDDeviceMagnetometerViewController.m
//  Tempo Utility
//
//  Created by Nikola Misic on 6/21/17.
//  Copyright © 2017 BlueMaestro. All rights reserved.
//

#import "TDDeviceMagnetometerViewController.h"
#import "TempoDiscDevice+CoreDataProperties.h"

@interface TDDeviceMagnetometerViewController ()

@end

@implementation TDDeviceMagnetometerViewController

- (void)fillData {
	[super fillData];
	//TODO: fill data for device here
	TempoDiscDevice *device = (TempoDiscDevice*)[TDSharedDevice sharedDevice].selectedDevice;
	_labelStatusValue.text = device.openCloseStatus.boolValue ? @"OPEN" : @"CLOSED";
	_labelNumberOfOpenEventsValue.text = @(device.openEventsCount.integerValue).stringValue;
	_labelNumberOfOccuredInLoggingPeriodValue.text = @(device.lastOpenInterval.integerValue).stringValue;
	_labelTotalEventsValue.text = @(device.totalEventsCount.integerValue).stringValue;
	
	for (UIImageView *box in self.boxImageViews) {
		box.image = [[UIImage imageNamed:device.openCloseStatus.boolValue ? @"Green Box" : @"red box"] resizableImageWithCapInsets:UIEdgeInsetsMake(12, 12, 12, 12)];
	}
}

@end
