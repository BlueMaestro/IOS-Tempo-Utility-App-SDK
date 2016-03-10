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
#define BM_MODEL_DISC 16

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
			if (d[2] == BM_MODEL_DISC) {
				return YES;
			}
		}
	}
	return NO;
}

- (void)fillWithData:(NSDictionary *)advertisedData name:(NSString *)name uuid:(nonnull NSString *)uuid {
	
	self.uuid = uuid;
	self.name = name;
	
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
			/**
			 *	Status bits
			 *	Not sure about data read
			 **/
			float temperatureStatus = (data[3] & 0x80) >> 7;
			float humidityStatus = (data[3] & 0x40) >> 6;
			float pressureStatus = ((data[3] & 0x20) >> 5);
			float accelerometerStatus = ((data[3] & 0x10) >> 4);
			float irStatus = (data[3] & 0x8) >> 3;
			
			float min = getInt(data[11],data[12]) / 10.0f;
			float avg = getInt(data[13],data[14]) / 10.0f;
			float max = getInt(data[15],data[16]) / 10.0f;
			
			float humidity = data[17];
			float pressure = getInt(data[18], data[19]);
			
			self.currentMinTemperature = [NSNumber numberWithFloat:min];
			self.currentMaxTemperature = [NSNumber numberWithFloat:max];
			self.currentTemperature = [NSNumber numberWithFloat:avg];
			self.currentHumidity = @(humidity);
			self.currentPressure = [NSNumber numberWithInt:pressure];
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


- (void)addData:(NSArray *)data forReadingType:(NSString *)type context:(NSManagedObjectContext *)context {
	ReadingType *targetReadingType;
	for (ReadingType *readingType in self.readingTypes) {
		if ([readingType.type isEqualToString:type]) {
			targetReadingType = readingType;
		}
	}
	//delete all data and insert again
	if (targetReadingType) {
		[context deleteObject:targetReadingType];
	}
	
	targetReadingType = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([ReadingType class]) inManagedObjectContext:context];
	[self addReadingTypesObject:targetReadingType];
	targetReadingType.type = type;
	
	NSDate *currentDate = [NSDate date];
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
		reading.timestamp = [currentDate dateByAddingTimeInterval:-3600*index];
		index++;
	}
	NSError *saveError;
	[context save:&saveError];
	if (saveError) {
		NSLog(@"Error saving data import: %@", saveError);
	}
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
