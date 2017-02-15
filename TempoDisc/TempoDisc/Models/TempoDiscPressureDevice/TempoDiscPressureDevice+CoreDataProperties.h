//
//  TempoDiscPressureDevice+CoreDataProperties.h
//  
//
//  Created by Nikola Misic on 2/15/17.
//
//

#import "TempoDiscPressureDevice+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface TempoDiscPressureDevice (CoreDataProperties)

+ (NSFetchRequest<TempoDiscPressureDevice *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSNumber *averageDayPressure;
@property (nullable, nonatomic, copy) NSNumber *pressure;
@property (nullable, nonatomic, copy) NSNumber *highestDayPressure;
@property (nullable, nonatomic, copy) NSNumber *highestPressure;
@property (nullable, nonatomic, copy) NSNumber *lowestDayPressure;
@property (nullable, nonatomic, copy) NSNumber *lowestPressure;

@end

NS_ASSUME_NONNULL_END
