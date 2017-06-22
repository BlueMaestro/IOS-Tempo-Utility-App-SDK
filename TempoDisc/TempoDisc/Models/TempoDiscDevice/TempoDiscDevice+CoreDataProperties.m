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
@dynamic version;
@dynamic numBreach;
@dynamic highestTemperature;
@dynamic highestHumidity;
@dynamic highestDew;
@dynamic lowestTemperature;
@dynamic lowestHumidity;
@dynamic lowestDew;
@dynamic highestDayTemperature;
@dynamic highestDayHumidity;
@dynamic highestDayDew;
@dynamic lowestDayTemperature;
@dynamic lowestDayHumidity;
@dynamic lowestDayDew;
@dynamic averageDayTemperature;
@dynamic averageDayHumidity;
@dynamic averageDayDew;
@dynamic logCount;
@dynamic globalIdentifier;
@dynamic averageDayPressure;
@dynamic pressure;
@dynamic highestDayPressure;
@dynamic highestPressure;
@dynamic lowestDayPressure;
@dynamic lowestPressure;
@dynamic altitude;
@dynamic totalButtonEvents;
@dynamic lastOpenInterval;
@dynamic totalEventsCount;
@dynamic openEventsCount;
@dynamic referenceDateRawNumber;
@dynamic openCloseStatus;
@dynamic logPointer;
@dynamic lightThreshold;
@dynamic lightStatus;
@dynamic currentLightLevel;

@end
