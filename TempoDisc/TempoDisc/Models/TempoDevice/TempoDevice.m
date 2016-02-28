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

int getInt(char lsb,char msb)
{
	return (((int) lsb) & 0xFF) | (((int) msb) << 8);
}

@implementation TempoDevice

// Insert code here to add functionality to your managed object subclass

+ (TempoDevice *)deviceWithName:(NSString *)name data:(NSDictionary *)data uuid:(nonnull NSString *)uuid context:(nonnull NSManagedObjectContext *)context {
	TempoDevice *device = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([TempoDevice class]) inManagedObjectContext:context];
	[device fillWithData:data name:name uuid:uuid];
	return device;
}

- (void)fillWithData:(NSDictionary *)advertisedData name:(NSString *)name uuid:(nonnull NSString *)uuid {
	
	self.uuid = uuid;
	self.name = name;
	
	NSData *custom = [advertisedData objectForKey:@"kCBAdvDataManufacturerData"];
	
	bool isTempoLegacy =  (custom == nil && [name isEqualToString:@"Tempo "]);
	bool isTempoT30 = false;
	bool isTempoTHP = false;
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
		}
	}
	else {
		//device is legacy
		self.modelType = @"TEMPO_LEGACY";
	}
	
	if (isTempoT30 || isTempoTHP) {
		char * data = (char*)[custom bytes];
		float min = getInt(data[3],data[4]) / 10.0f;
		float avg = getInt(data[5],data[6]) / 10.0f;
		float max = getInt(data[7],data[8]) / 10.0f;
		
		self.modelType = deviceType;
		
		self.currentMinTemperature = [NSNumber numberWithFloat:min];
		self.currentMaxTemperature = [NSNumber numberWithFloat:max];
		self.currentTemperature = [NSNumber numberWithFloat:avg];
		
		if (isTempoTHP) {
			int humidity = data[9];
			int pressure = getInt(data[10],data[11]);
			int pressureDelta = getInt(data[12],data[13]);
			
			self.currentPressure = [NSNumber numberWithInt:pressure];
			self.currentHumidity = [NSNumber numberWithInt:humidity];
			self.currentPressureDelta = [NSNumber numberWithInt:pressureDelta];
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


- (void)addData:(NSArray *)data forReadingType:(NSString *)type context:(NSManagedObjectContext *)context {
	ReadingType *targetReadingType;
	for (ReadingType *readingType in self.readingTypes) {
		if ([readingType.type isEqualToString:type]) {
			targetReadingType = readingType;
		}
	}
	if (!targetReadingType) {
		targetReadingType = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([ReadingType class]) inManagedObjectContext:context];
		targetReadingType.device = self;
	}
	//delete all data and insert again
	for (Reading *reading in self.readingTypes) {
		[context deleteObject:reading];
	}
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
	}
	NSError *saveError;
	[context save:&saveError];
}

@end
