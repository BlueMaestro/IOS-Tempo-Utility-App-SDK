//
//  TempoDevice+CoreDataProperties.m
//  
//
//  Created by Nikola Misic on 2/28/16.
//
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "TempoDevice+CoreDataProperties.h"

@implementation TempoDevice (CoreDataProperties)

@dynamic name;
@dynamic battery;
@dynamic modelType;
@dynamic version;
@dynamic currentTemperature;
@dynamic currentHumidity;
@dynamic currentPressure;
@dynamic readingTypes;

@end