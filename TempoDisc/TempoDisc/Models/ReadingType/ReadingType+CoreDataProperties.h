//
//  ReadingType+CoreDataProperties.h
//  
//
//  Created by Nikola Misic on 2/28/16.
//
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "ReadingType.h"
#import "Reading.h"

NS_ASSUME_NONNULL_BEGIN

@interface ReadingType (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *type;
@property (nullable, nonatomic, retain) NSDate *lastHarvest;
@property (nullable, nonatomic, retain) TempoDevice *device;
@property (nullable, nonatomic, retain) NSSet<Reading *> *readings;

@end

@interface ReadingType (CoreDataGeneratedAccessors)

- (void)addReadingsObject:(Reading *)value;
- (void)removeReadingsObject:(Reading *)value;
- (void)addReadings:(NSSet<Reading *> *)values;
- (void)removeReadings:(NSSet<Reading *> *)values;

@end

NS_ASSUME_NONNULL_END
