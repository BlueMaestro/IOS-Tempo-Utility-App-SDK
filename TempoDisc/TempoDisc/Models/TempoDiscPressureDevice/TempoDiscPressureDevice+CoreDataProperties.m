//
//  TempoDiscPressureDevice+CoreDataProperties.m
//  
//
//  Created by Nikola Misic on 2/15/17.
//
//

#import "TempoDiscPressureDevice+CoreDataProperties.h"

@implementation TempoDiscPressureDevice (CoreDataProperties)

+ (NSFetchRequest<TempoDiscPressureDevice *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"TempoDiscPressureDevice"];
}

@dynamic averageDayPressure;
@dynamic pressure;
@dynamic highestDayPressure;
@dynamic highestPressure;
@dynamic lowestDayPressure;
@dynamic lowestPressure;

@end
