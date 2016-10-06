//
//  TempoDevice+CoreDataProperties.h
//  
//
//  Created by Nikola Misic on 2/28/16.
//
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "TempoDevice.h"
#import "ReadingType.h"

NS_ASSUME_NONNULL_BEGIN

@interface TempoDevice (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *uuid;
@property (nullable, nonatomic, retain) NSString *name;
@property (nullable, nonatomic, retain) NSDecimalNumber *battery;
@property (nullable, nonatomic, retain) NSString *modelType;
@property (nullable, nonatomic, retain) NSString *version;
@property (nullable, nonatomic, retain) NSNumber *currentTemperature;
@property (nullable, nonatomic, retain) NSNumber *currentMinTemperature;
@property (nullable, nonatomic, retain) NSNumber *currentMaxTemperature;
@property (nullable, nonatomic, retain) NSNumber *currentHumidity;
@property (nullable, nonatomic, retain) NSNumber *currentPressure;
@property (nullable, nonatomic, retain) NSNumber *currentPressureDelta;
@property (nullable, nonatomic, retain) NSDate *lastDownload;
@property (nullable, nonatomic, retain) NSNumber *isBlueMaestroDevice;
@property (nullable, nonatomic, retain) NSNumber *isFahrenheit;//BOOL
@property (nullable, nonatomic, retain) NSNumber *inRange;//BOOL, transient

@property (nullable, nonatomic, retain) NSSet<ReadingType *> *readingTypes;

@end

@interface TempoDevice (CoreDataGeneratedAccessors)

- (void)addReadingTypesObject:(ReadingType *)value;
- (void)removeReadingTypesObject:(ReadingType *)value;
- (void)addReadingTypes:(NSSet<ReadingType *> *)values;
- (void)removeReadingTypes:(NSSet<ReadingType *> *)values;

@end

NS_ASSUME_NONNULL_END
