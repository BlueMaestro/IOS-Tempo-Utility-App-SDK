//
//  TDHelper.h
//  TempoDisc
//
//  Created by Nikola Misic on 2/28/16.
//  Copyright © 2016 BlueMaestro. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TempoDevice.h"
#import "TDTempoDisc.h"

typedef enum : NSInteger {
	TempoReadingTypeTemperature,
	TempoReadingTypeHumidity,
	TempoReadingTypePressure,
	TempoReadingTypeDewPoint
} TempoReadingType;

@interface TDHelper : NSObject

+ (NSNumber*)temperature:(NSNumber *)temp forDevice:(TempoDevice *)device;
+ (NSNumber *)temperature:(NSNumber *)temp forDiscDevice:(TDTempoDisc *)device;

@end
