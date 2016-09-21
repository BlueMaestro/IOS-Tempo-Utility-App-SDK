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

@dynamic uuid;
@dynamic name;
@dynamic battery;
@dynamic modelType;
@dynamic version;
@dynamic currentTemperature;
@dynamic currentMaxTemperature;
@dynamic currentMinTemperature;
@dynamic currentHumidity;
@dynamic currentPressure;
@dynamic currentPressureDelta;
@dynamic lastDownload;
@dynamic readingTypes;
@dynamic isBlueMaestroDevice;
@dynamic isFahrenheit;

@end
