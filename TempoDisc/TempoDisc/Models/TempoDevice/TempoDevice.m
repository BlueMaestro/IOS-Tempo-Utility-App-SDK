//
//  TempoDevice.m
//  
//
//  Created by Nikola Misic on 2/28/16.
//
//

#import "TempoDevice.h"

#define MANUF_ID_BLUE_MAESTRO 0x0133
#define BM_MODEL_T30 0
#define BM_MODEL_THP 1
#define BM_MODEL_DISC '\x16'

int getInt(char lsb,char msb)
{
	return (((int) lsb) & 0xFF) | (((int) msb) << 8);
}

@implementation TempoDevice

@dynamic peripheral;

// Insert code here to add functionality to your managed object subclass

+ (TempoDevice *)deviceWithName:(NSString *)name data:(NSDictionary *)data uuid:(nonnull NSString *)uuid context:(nonnull NSManagedObjectContext *)context {
	TempoDevice *device = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([TempoDevice class]) inManagedObjectContext:context];
	[device fillWithData:data name:name uuid:uuid];
	return device;
}

+ (BOOL)isTempoDiscDeviceWithAdvertisementData:(NSDictionary*)data {
	NSData *custom = [data objectForKey:@"kCBAdvDataManufacturerData"];
	//BlueMaestro device
	if (custom != nil)
	{
		unsigned char * d = (unsigned char*)[custom bytes];
		unsigned int manuf = d[1] << 8 | d[0];
		
		//Is this one of ours?
		if (manuf == MANUF_ID_BLUE_MAESTRO) {
			if (d[2] == BM_MODEL_DISC /*||
				d[2] == BM_MODEL_THP ||
				d[2] == BM_MODEL_T30*/) {
				return YES;
			}
		}
	}
	return NO;
}


+ (BOOL)isBlueMaestroDeviceWithAdvertisementData:(NSDictionary*)data {
	NSData *custom = [data objectForKey:@"kCBAdvDataManufacturerData"];
	//BlueMaestro device
	if (custom != nil)
	{
		unsigned char * d = (unsigned char*)[custom bytes];
		unsigned int manuf = d[1] << 8 | d[0];
		
		//Is this one of ours?
		if (manuf == MANUF_ID_BLUE_MAESTRO) {
			return YES;
		}
	}
	return NO;
}

+ (BOOL)hasManufacturerData:(NSDictionary*)data {
	if (data[@"kCBAdvDataManufacturerData"]) {
		return YES;
	}
	else {
		return NO;
	}
}

- (void)fillWithData:(NSDictionary *)advertisedData name:(NSString *)name uuid:(nonnull NSString *)uuid {
	
	self.uuid = uuid;
	self.name = advertisedData[@"kCBAdvDataLocalName"];
	
	NSData *custom = [advertisedData objectForKey:@"kCBAdvDataManufacturerData"];
	
	bool isTempoLegacy =  (custom == nil && [name isEqualToString:@"Tempo "]);
	bool isTempoT30 = false;
	bool isTempoTHP = false;
	bool isTempoDisc = false;
	NSString *deviceType = nil;
	
	//BlueMaestro device
	if (custom != nil)
	{
		unsigned char * d = (unsigned char*)[custom bytes];
		unsigned int manuf = d[1] << 8 | d[0];
		
		//Is this one of ours?
		if (manuf == MANUF_ID_BLUE_MAESTRO) {
			if (d[2] == BM_MODEL_T30) {
				deviceType = @"TEMPO_T30";
				isTempoT30 = true;
			} else if (d[2] == BM_MODEL_THP) {
				deviceType = @"TEMPO_THP";
				isTempoTHP = true;
			}
			else if (d[2] == BM_MODEL_DISC) {
				deviceType = @"TEMPO_DISC";
				isTempoDisc = true;
			}
		}
	}
	else {
		//device is legacy
		self.modelType = @"TEMPO_LEGACY";
	}
	if (!isTempoLegacy) {
		self.modelType = deviceType;
		char * data = (char*)[custom bytes];
		if (isTempoDisc) {
			
		}
		else {
			float min = getInt(data[3],data[4]) / 10.0f;
			float avg = getInt(data[5],data[6]) / 10.0f;
			float max = getInt(data[7],data[8]) / 10.0f;
			
			self.currentMinTemperature = [NSNumber numberWithFloat:min];
			self.currentMaxTemperature = [NSNumber numberWithFloat:max];
			self.currentTemperature = [NSNumber numberWithFloat:avg];
			
			if (!isTempoT30) {
				int humidity = data[9];
				self.currentHumidity = [NSNumber numberWithInt:humidity];
				
				if (isTempoTHP) {
					int pressure = getInt(data[10],data[11]);
					int pressureDelta = getInt(data[12],data[13]);
					
					self.currentPressure = [NSNumber numberWithInt:pressure];
					self.currentPressureDelta = [NSNumber numberWithInt:pressureDelta];
				}
			}
		}
	}
}

- (TempoDeviceType)deviceType {
	if ([self.modelType isEqualToString:@"TEMPO_LEGACY"]) {
		return TempoDeviceTypeLegacy;
	}
	else if ([self.modelType isEqualToString:@"TEMPO_T30"]) {
		return TempoDeviceTypeT30;
	}
	else if ([self.modelType isEqualToString:@"TEMPO_THP"]) {
		return TempoDeviceTypeT30;
	}
	else {
		return TempoDeviceTypeUnknown;
	}
}

- (void)addData:(NSArray *)data forReadingType:(NSString *)type startTimestamp:(NSDate*)timestamp interval:(NSInteger)interval context:(NSManagedObjectContext *)context {
	ReadingType *targetReadingType;
	for (ReadingType *readingType in self.readingTypes) {
		if ([readingType.type isEqualToString:type]) {
			targetReadingType = readingType;
		}
	}

	//if there is data reading should be added at the end
	BOOL addToExistingData = NO;
	if (targetReadingType) {
		addToExistingData = YES;
	}
	
	targetReadingType = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([ReadingType class]) inManagedObjectContext:context];
	[self addReadingTypesObject:targetReadingType];
	targetReadingType.type = type;
	
//	NSLog(@"Start timestamp: %@", timestamp);
	NSInteger index = 0;
	for (NSArray *sample in data) {
		Reading *reading = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([Reading class]) inManagedObjectContext:context];
		reading.type = targetReadingType;
		if (sample.count > 2) {
			reading.minValue = [sample firstObject];
			reading.maxValue = [sample lastObject];
			reading.avgValue = sample[1];
		}
		else {
			reading.avgValue = [sample firstObject];
		}
		
		if (addToExistingData) {
			reading.timestamp = [timestamp dateByAddingTimeInterval:interval*index];
		}
		else {
			reading.timestamp = [timestamp dateByAddingTimeInterval:-interval*((NSInteger)data.count-1-index)];
		}
//		NSLog(@"Timetamp: %@", reading.timestamp);
		index++;
	}
	NSError *saveError;
	[context save:&saveError];
	if (saveError) {
		NSLog(@"Error saving data import: %@", saveError);
	}
}

- (void)addData:(NSArray *)data forReadingType:(NSString *)type context:(NSManagedObjectContext *)context {
	[self addData:data forReadingType:type startTimestamp:[NSDate date] interval:-3600 context:context];
}

- (NSArray *)readingsForType:(NSString *)typeOfReading {
	for (ReadingType *readingType in self.readingTypes) {
		if ([readingType.type isEqualToString:typeOfReading]) {
			return [readingType.readings allObjects];
		}
	}
	return @[];
}

@end
