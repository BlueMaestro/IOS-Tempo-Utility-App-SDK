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

typedef enum : NSInteger {
	TempoDeviceTypeUnknown = 0,
	TempoDeviceTypeLegacy,
	TempoDeviceTypeT30,
	TempoDeviceTypeTHP,
	TempoDeviceType22,
	TempoDeviceType23,
	TempoDeviceType27
	
} TempoDeviceType ;

NS_ASSUME_NONNULL_BEGIN

@interface TempoDevice : NSManagedObject

// Insert code here to declare functionality of your managed object subclass

@property (nullable ,nonatomic, strong) LGPeripheral *peripheral;

- (NSInteger)classID;

+ (BOOL)isTempoDiscDeviceWithAdvertisementData:(NSDictionary*)custom;
+ (BOOL)isBlueMaestroDeviceWithAdvertisementData:(NSDictionary*)data;
+ (BOOL)isTempoDisc22WithAdvertisementDate:(NSDictionary*)data;
+ (BOOL)isTempoDisc23WithAdvertisementDate:(NSDictionary*)data;
+ (BOOL)isTempoDisc27WithAdvertisementDate:(NSDictionary*)data;
+ (BOOL)hasManufacturerData:(NSDictionary*)data;

+ (TempoDevice*)deviceWithName:(NSString*)name data:(NSDictionary*)data uuid:(NSString*)uuid context:(NSManagedObjectContext*)context;
- (void)deleteOldData:(NSString *)type context:(NSManagedObjectContext *)context;
- (void)addData:(NSArray *)data forReadingType:(NSString *)type startTimestamp:(NSDate*)timestamp interval:(NSInteger)interval context:(NSManagedObjectContext *)context;

- (TempoDeviceType)deviceType;

- (void)addDataFirst:(NSArray*)data forReadingType:(NSString*)type context:(NSManagedObjectContext*)context;
- (void)fillWithData:(NSDictionary *)advertisedData name:(NSString *)name uuid:(nonnull NSString *)uuid;
- (NSArray*)readingsForType:(NSString*)type;
- (BOOL)hasDataForType:(NSString*)type;

@end

NS_ASSUME_NONNULL_END

#import "TempoDevice+CoreDataProperties.h"
