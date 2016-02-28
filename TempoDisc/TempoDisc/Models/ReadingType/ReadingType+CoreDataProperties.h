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

NS_ASSUME_NONNULL_BEGIN

@interface ReadingType (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *type;
@property (nullable, nonatomic, retain) NSDate *lastHarvest;
@property (nullable, nonatomic, retain) TempoDevice *device;
@property (nullable, nonatomic, retain) NSSet<NSManagedObject *> *readings;

@end

@interface ReadingType (CoreDataGeneratedAccessors)

- (void)addReadingsObject:(NSManagedObject *)value;
- (void)removeReadingsObject:(NSManagedObject *)value;
- (void)addReadings:(NSSet<NSManagedObject *> *)values;
- (void)removeReadings:(NSSet<NSManagedObject *> *)values;

@end

NS_ASSUME_NONNULL_END
