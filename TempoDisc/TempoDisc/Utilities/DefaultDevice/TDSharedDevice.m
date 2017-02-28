//
//  TDSharedDevice.m
//  TempoDisc
//
//  Created by Nikola Misic on 2/28/16.
//  Copyright © 2016 BlueMaestro. All rights reserved.
//

#import "TDSharedDevice.h"

@implementation TDSharedDevice

+ (TDSharedDevice *)sharedDevice {
	static TDSharedDevice *singleton = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		singleton = [[TDSharedDevice alloc] init];
	});
	return singleton;
}

@end
