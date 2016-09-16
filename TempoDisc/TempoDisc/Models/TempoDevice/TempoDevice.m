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
			if (d[2] == BM_MODEL_DISC/* ||
				d[2] == BM_MODEL_THP ||
				d[2] == BM_MODEL_T30*/) {
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
			float version = data[2];
			float battery = data[3];
			float timerInterval = getInt(data[5], data[4]);
			float intervalCounter = getInt(data[7], data[6]);
			float temperature = getInt(data[9], data[8]);
			float humidity = getInt(data[11], data[10]);
			float dewPoint = getInt(data[13], data[12]);
			float mode = data[14];
			float numBreach = data[15];
			float timeAtLastBreach = getInt(data[17], data[16]);
			float nameLength = data[18];
			
			float highestTemp = getInt(data[21], data[20]);
			float highestHumidity = getInt(data[23], data[24]);
			float lowestTemperature = getInt(data[26], data[25]);
			float lowestHumidity = getInt(data[28], data[27]);
			float highDayTemp = getInt(data[30], data[29]);
			float highDayHumidity = getInt(data[32], data[31]);
			float highDayDew = getInt(data[34], data[33]);
			float lowDayTemp = getInt(data[36], data[35]);
			float lowDayHumidity = getInt(data[38], data[37]);
			float lowDayDew = getInt(data[40], data[39]);
			float avgDayTemperature = getInt(data[42], data[41]);
			float avgDayHumidity = getInt(data[44], data[43]);
			float avgDayDew = getInt(data[46], data[45]);
			
			/*self.currentMinTemperature = [NSNumber numberWithFloat:min];
			self.currentMaxTemperature = [NSNumber numberWithFloat:max];
			self.currentTemperature = [NSNumber numberWithFloat:avg];
			self.currentPressure = [NSNumber numberWithInt:pressure];*/
			self.currentHumidity = @(humidity);
			NSLog(@"---------------------------------------------------------------");
			NSLog(@"PARSING TEMPO DISC DEVICE DATA:");
			NSLog(@"Raw data: %@", custom);
			NSLog(@"Version: %f", version);
			NSLog(@"Battery: %f", battery);
			NSLog(@"Timer interval: %f", timerInterval);
			NSLog(@"Interval Counter: %f", intervalCounter);
			NSLog(@"Temperature: %f", temperature);
			NSLog(@"Humidity: %f", humidity);
			NSLog(@"Dew Point: %f", dewPoint);
			NSLog(@"Mode: %f", mode);
			NSLog(@"Number of breaches: %f", numBreach);
			NSLog(@"Time at last breach: %f", timeAtLastBreach);
			NSLog(@"Name length: %f", nameLength);
			NSLog(@"Highest Temperature: %f", highestTemp);
			NSLog(@"Highest Humidity: %f", highestHumidity);
			NSLog(@"Lowest Temperature: %f", lowestTemperature);
			NSLog(@"Lowest Humidity: %f", lowestHumidity);
			NSLog(@"Highest 24h Temperature: %f", highDayTemp);
			NSLog(@"Highest 24h Humidity: %f", highDayHumidity);
			NSLog(@"Highest 24h Dew: %f", highDayDew);
			NSLog(@"Lowest 24h Temperature: %f", lowDayTemp);
			NSLog(@"Lowest 24h Humidity: %f", lowDayHumidity);
			NSLog(@"Lowest 24h Dew: %f", lowDayDew);
			NSLog(@"Average 24h Temperature: %f", avgDayTemperature);
			NSLog(@"Average 24h Humidity: %f", avgDayHumidity);
			NSLog(@"Average 24h Dew: %f", avgDayDew);
			NSLog(@"---------------------------------------------------------------");
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
