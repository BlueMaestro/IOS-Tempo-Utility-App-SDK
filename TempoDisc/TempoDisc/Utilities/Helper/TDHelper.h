//
//  TDHelper.h
//  TempoDisc
//
//  Created by Nikola Misic on 2/28/16.
//  Copyright © 2016 BlueMaestro. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum : NSInteger {
	TempoReadingTypeTemperature,
	TempoReadingTypeHumidity,
	TempoReadingTypePressure
} TempoReadingType;

@interface TDHelper : NSObject

@end
