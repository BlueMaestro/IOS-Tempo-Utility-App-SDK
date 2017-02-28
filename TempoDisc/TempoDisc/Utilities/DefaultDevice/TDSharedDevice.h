//
//  TDSharedDevice.h
//  TempoDisc
//
//  Created by Nikola Misic on 2/28/16.
//  Copyright © 2016 BlueMaestro. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TDTempoDisc.h"
#import "TempoDevice.h"

@interface TDSharedDevice : NSObject

@property (nonatomic, strong) TDTempoDisc *activeDevice;
@property (nonatomic, strong) TempoDevice *selectedDevice;

+ (TDSharedDevice*)sharedDevice;

@end
