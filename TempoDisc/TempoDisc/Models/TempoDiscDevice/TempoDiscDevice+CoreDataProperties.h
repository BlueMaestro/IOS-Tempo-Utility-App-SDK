//
//  TempoDiscDevice+CoreDataProperties.h
//  
//
//  Created by Nikola Misic on 9/21/16.
//
//

#import "TempoDiscDevice+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface TempoDiscDevice (CoreDataProperties)

+ (NSFetchRequest<TempoDiscDevice *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSNumber *timerInterval;
@property (nullable, nonatomic, copy) NSNumber *intervalCounter;
@property (nullable, nonatomic, copy) NSNumber *dewPoint;
@property (nullable, nonatomic, copy) NSNumber *mode;
@property (nullable, nonatomic, copy) NSNumber *version;
@property (nullable, nonatomic, copy) NSNumber *numBreach;
@property (nullable, nonatomic, copy) NSNumber *highestTemperature;
@property (nullable, nonatomic, copy) NSNumber *highestHumidity;
@property (nullable, nonatomic, copy) NSNumber *highestDew;
@property (nullable, nonatomic, copy) NSNumber *lowestTemperature;
@property (nullable, nonatomic, copy) NSNumber *lowestHumidity;
@property (nullable, nonatomic, copy) NSNumber *lowestDew;
@property (nullable, nonatomic, copy) NSNumber *highestDayTemperature;
@property (nullable, nonatomic, copy) NSNumber *highestDayHumidity;
@property (nullable, nonatomic, copy) NSNumber *highestDayDew;
@property (nullable, nonatomic, copy) NSNumber *lowestDayTemperature;
@property (nullable, nonatomic, copy) NSNumber *lowestDayHumidity;
@property (nullable, nonatomic, copy) NSNumber *lowestDayDew;
@property (nullable, nonatomic, copy) NSNumber *averageDayTemperature;
@property (nullable, nonatomic, copy) NSNumber *averageDayHumidity;
@property (nullable, nonatomic, copy) NSNumber *averageDayDew;
@property (nullable, nonatomic, copy) NSNumber *logCount;
@property (nullable, nonatomic, copy) NSNumber *referenceDateRawNumber;
@property (nullable, nonatomic, retain) NSNumber *globalIdentifier;
@property (nullable, nonatomic, copy) NSNumber *averageDayPressure;
@property (nullable, nonatomic, copy) NSNumber *pressure;
@property (nullable, nonatomic, copy) NSNumber *highestDayPressure;
@property (nullable, nonatomic, copy) NSNumber *highestPressure;
@property (nullable, nonatomic, copy) NSNumber *lowestDayPressure;
@property (nullable, nonatomic, copy) NSNumber *lowestPressure;
@property (nullable, nonatomic, copy) NSNumber *altitude;

//device 32
@property (nullable, nonatomic, strong) NSNumber *humSensitivityLevel;
@property (nullable, nonatomic, strong) NSNumber *pestSensitivityLevel;
@property (nullable, nonatomic, strong) NSNumber *force;
@property (nullable, nonatomic, strong) NSNumber *movementMeasurePeriod;
@property (nullable, nonatomic, strong) NSNumber *dateNumber;
@property (nullable, nonatomic, strong) NSNumber *buttonPressControl;
@property (nullable, nonatomic, strong) NSNumber *lastPestDetectRate;
@property (nullable, nonatomic, strong) NSNumber *lastHumDetectRate;
@property (nullable, nonatomic, strong) NSNumber *totalPestEventsDetects;
@property (nullable, nonatomic, strong) NSNumber *totalHumEventsDetects;
@property (nullable, nonatomic, strong) NSNumber *lastButtonDetected;

//device 42
@property (nullable, nonatomic, strong) NSNumber *totalButtonEvents;

@end

NS_ASSUME_NONNULL_END
