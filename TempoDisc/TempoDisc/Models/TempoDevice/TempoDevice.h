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

@property (nonatomic, strong) LGPeripheral *peripheral;

+ (TempoDevice*)deviceWithName:(NSString*)name data:(NSDictionary*)data uuid:(NSString*)uuid context:(NSManagedObjectContext*)context;
- (void)fillWithData:(NSDictionary*)data name:(NSString*)name uuid:(NSString*)uuid;

- (TempoDeviceType)deviceType;

@end

NS_ASSUME_NONNULL_END

#import "TempoDevice+CoreDataProperties.h"
