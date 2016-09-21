//
//  TempoDiscDevice+CoreDataProperties.m
//  
//
//  Created by Nikola Misic on 9/21/16.
//
//

#import "TempoDiscDevice+CoreDataProperties.h"

@implementation TempoDiscDevice (CoreDataProperties)

+ (NSFetchRequest<TempoDiscDevice *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"TempoDiscDevice"];
}

@dynamic timerInterval;
@dynamic intervalCounter;
@dynamic dewPoint;
@dynamic mode;
@dynamic numBreach;
@dynamic highestTemperature;
@dynamic highestHumidity;
@dynamic lowestTemperature;
@dynamic lowestHumidity;
@dynamic highestDayTemperature;
@dynamic highestDayHumidity;
@dynamic highestDayDew;
@dynamic lowestDayTemperature;
@dynamic lowestDayHumidity;
@dynamic lowestDayDew;
@dynamic averageDayTemperature;
@dynamic averageDayHumidity;
@dynamic averageDayDew;

@end
