//
//  TDDeviceLuminosityInfoViewController.m
//  Tempo Utility
//
//  Created by Nikola Misic on 6/22/17.
//  Copyright © 2017 BlueMaestro. All rights reserved.
//

#import "TDDeviceLuminosityInfoViewController.h"
#import "TempoDiscDevice+CoreDataProperties.h"

@interface TDDeviceLuminosityInfoViewController ()

@end

@implementation TDDeviceLuminosityInfoViewController

- (void)fillData {
	[super fillData];
	_labelCurrentLuminosityLevelValue.text = @([(TempoDiscDevice*)[TDSharedDevice sharedDevice].selectedDevice currentLightLevel].integerValue).stringValue;
}

@end
