//
//  TDDefaultDevice.h
//  TempoDisc
//
//  Created by Nikola Misic on 2/28/16.
//  Copyright © 2016 BlueMaestro. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TempoDevice.h"

@interface TDDefaultDevice : NSObject

@property (nonatomic, strong) TempoDevice *selectedDevice;

+ (TDDefaultDevice*)sharedDevice;

@end
