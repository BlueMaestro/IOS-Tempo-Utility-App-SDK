//
//  Reading+CoreDataProperties.h
//  
//
//  Created by Nikola Misic on 2/28/16.
//
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "Reading.h"

NS_ASSUME_NONNULL_BEGIN

@interface Reading (CoreDataProperties)

@property (nullable, nonatomic, retain) NSDecimalNumber *avgValue;
@property (nullable, nonatomic, retain) NSDecimalNumber *minValue;
@property (nullable, nonatomic, retain) NSDecimalNumber *maxValue;
@property (nullable, nonatomic, retain) NSDate *timestamp;
@property (nullable, nonatomic, retain) ReadingType *type;

@end

NS_ASSUME_NONNULL_END
