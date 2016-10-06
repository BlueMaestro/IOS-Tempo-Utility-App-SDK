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
@property (nullable, nonatomic, copy) NSDecimalNumber *dewPoint;
@property (nullable, nonatomic, copy) NSNumber *mode;
@property (nullable, nonatomic, copy) NSNumber *numBreach;
@property (nullable, nonatomic, copy) NSNumber *highestTemperature;
@property (nullable, nonatomic, copy) NSNumber *highestHumidity;
@property (nullable, nonatomic, copy) NSNumber *lowestTemperature;
@property (nullable, nonatomic, copy) NSNumber *lowestHumidity;
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

@end

NS_ASSUME_NONNULL_END
