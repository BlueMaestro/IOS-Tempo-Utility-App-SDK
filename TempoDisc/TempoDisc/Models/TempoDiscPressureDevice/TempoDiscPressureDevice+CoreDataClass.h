//
//  TempoDiscPressureDevice+CoreDataClass.h
//  
//
//  Created by Nikola Misic on 2/15/17.
//
//

#import <Foundation/Foundation.h>
#import "TempoDiscDevice+CoreDataClass.h"

NS_ASSUME_NONNULL_BEGIN

@interface TempoDiscPressureDevice : TempoDiscDevice

/**
 *	Calculated properties
 **/
- (float)averageDayDewPoint;
- (float)highestDayDewPoint;
- (float)highestDewPoint;
- (float)lowestDayDewPoint;
- (float)lowestDewPoint;
- (float)dewPoint;

@end

NS_ASSUME_NONNULL_END

#import "TempoDiscPressureDevice+CoreDataProperties.h"
