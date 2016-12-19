//
//  TempoDevice.h
//  
//
//  Created by Nikola Misic on 2/28/16.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <LGPeripheral.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSInteger {
	TempoDeviceTypeUnknown = 0,
	TempoDeviceTypeLegacy,
	TempoDeviceTypeT30,
	TempoDeviceTypeTHP,
	
} TempoDeviceType ;

@interface TempoDevice : NSManagedObject

// Insert code here to declare functionality of your managed object subclass

@property (nullable ,nonatomic, strong) LGPeripheral *peripheral;

+ (BOOL)isTempoDiscDeviceWithAdvertisementData:(NSDictionary*)custom;
+ (BOOL)isBlueMaestroDeviceWithAdvertisementData:(NSDictionary*)data;
+ (BOOL)hasManufacturerData:(NSDictionary*)data;

+ (TempoDevice*)deviceWithName:(NSString*)name data:(NSDictionary*)data uuid:(NSString*)uuid context:(NSManagedObjectContext*)context;
- (void)deleteOldData:(NSString *)type context:(NSManagedObjectContext *)context;
- (void)addData:(NSArray *)data forReadingType:(NSString *)type startTimestamp:(NSDate*)timestamp interval:(NSInteger)interval context:(NSManagedObjectContext *)context;

- (TempoDeviceType)deviceType;

- (void)addDataFirst:(NSArray*)data forReadingType:(NSString*)type context:(NSManagedObjectContext*)context;
- (void)fillWithData:(NSDictionary *)advertisedData name:(NSString *)name uuid:(nonnull NSString *)uuid;
- (NSArray*)readingsForType:(NSString*)type;

@end

NS_ASSUME_NONNULL_END

#import "TempoDevice+CoreDataProperties.h"
