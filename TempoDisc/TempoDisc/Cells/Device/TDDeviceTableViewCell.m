//
//  TDDeviceTableViewCell.m
//  TempoDisc
//
//  Created by Nikola Misic on 2/28/16.
//  Copyright © 2016 BlueMaestro. All rights reserved.
//

#import "TDDeviceTableViewCell.h"

@implementation TDDeviceTableViewCell

#pragma mark - Public methods

- (void)setupBatteryStatus:(TempoBatteryStatus)status {
	UIColor *backgroundColor = [UIColor clearColor];
	NSString *labelTitle = NSLocalizedString(@"None", nil);
	switch (status) {
	case TempoBatteryStatusGood:
			backgroundColor = [UIColor colorWithRed:27/255.0 green:237/255.0 blue:52/255.0 alpha:1.0];
			labelTitle = NSLocalizedString(@"Good", nil);
			break;
		default:
			break;
	}
	
	_labelDeviceBattery.backgroundColor = backgroundColor;
	_labelDeviceBattery.text = labelTitle;
}

@end
