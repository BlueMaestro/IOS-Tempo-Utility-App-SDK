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

NS_ASSUME_NONNULL_BEGIN

@interface TempoDevice (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *name;
@property (nullable, nonatomic, retain) NSDecimalNumber *battery;
@property (nullable, nonatomic, retain) NSString *modelType;
@property (nullable, nonatomic, retain) NSString *version;
@property (nullable, nonatomic, retain) NSNumber *currentTemperature;
@property (nullable, nonatomic, retain) NSNumber *currentHumidity;
@property (nullable, nonatomic, retain) NSNumber *currentPressure;
@property (nullable, nonatomic, retain) NSSet<NSManagedObject *> *readingTypes;

@end

@interface TempoDevice (CoreDataGeneratedAccessors)

- (void)addReadingTypesObject:(NSManagedObject *)value;
- (void)removeReadingTypesObject:(NSManagedObject *)value;
- (void)addReadingTypes:(NSSet<NSManagedObject *> *)values;
- (void)removeReadingTypes:(NSSet<NSManagedObject *> *)values;

@end

NS_ASSUME_NONNULL_END
