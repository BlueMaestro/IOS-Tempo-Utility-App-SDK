//
//  TempoDiscDevice+CoreDataClass.h
//  
//
//  Created by Nikola Misic on 9/21/16.
//
//

#import <Foundation/Foundation.h>
#import "TempoDevice.h"

NS_ASSUME_NONNULL_BEGIN

@interface TempoDiscDevice : TempoDevice

- (void)fillDataForPersistentStore:(TDTempoDisc*)device;

@end

NS_ASSUME_NONNULL_END

#import "TempoDiscDevice+CoreDataProperties.h"
