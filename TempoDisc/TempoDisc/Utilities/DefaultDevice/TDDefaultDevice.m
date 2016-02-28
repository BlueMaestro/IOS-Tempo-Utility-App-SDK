//
//  TDDefaultDevice.m
//  TempoDisc
//
//  Created by Nikola Misic on 2/28/16.
//  Copyright © 2016 BlueMaestro. All rights reserved.
//

#import "TDDefaultDevice.h"

@implementation TDDefaultDevice

+ (TDDefaultDevice *)sharedDevice {
	static TDDefaultDevice *singleton = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		singleton = [[TDDefaultDevice alloc] init];
	});
	return singleton;
}

@end
