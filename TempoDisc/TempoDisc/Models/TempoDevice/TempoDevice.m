//
//  TempoDevice.m
//  
//
//  Created by Nikola Misic on 2/28/16.
//
//

#import "TempoDevice.h"
#import "TempoDiscDevice+CoreDataClass.h"

#define MANUF_ID_BLUE_MAESTRO 0x0133
#define BM_MODEL_T30 0
#define BM_MODEL_THP 1
#define BM_MODEL_DISC '\x16'
#define BM_MODEL_DISC_23 '\x17'

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

+ (BOOL)isTempoDisc23WithAdvertisementDate:(NSDictionary*)data {
    NSData *custom = [data objectForKey:@"kCBAdvDataManufacturerData"];
    //BlueMaestro device
    if (custom != nil)
    {
        unsigned char * d = (unsigned char*)[custom bytes];
        unsigned int manuf = d[1] << 8 | d[0];
        
        //Is this one of ours?
        if (manuf == MANUF_ID_BLUE_MAESTRO) {
            if (d[2] == BM_MODEL_DISC_23) {
            return YES;
            }
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
    bool isTempoDisc23 = false;
	NSString *deviceType = nil;
	
	//BlueMaestro device
	if (custom != nil) {
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
            else if (d[2] == BM_MODEL_DISC_23) {
                deviceType = @"TEMPO_DISC_23";
                isTempoDisc23 = true;
            }
		}
	} else {
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
    else if ([self.modelType isEqualToString:@"TEMPO_DISC_23"]) {
        return TempoDeviceType23;
    }
	else {
		return TempoDeviceTypeUnknown;
	}
}

- (void)deleteOldData:(NSString *)type context:(NSManagedObjectContext *)context {
    
    NSString *readingType;
    readingType = type;
    for (ReadingType *type in [TDDefaultDevice sharedDevice].selectedDevice.readingTypes) {
        if ([type.type isEqualToString:readingType]) {
            [[TDDefaultDevice sharedDevice].selectedDevice removeReadingTypesObject:type];
            break;
        }
    }
    /*
    ReadingType *targetReadingType;
    for (ReadingType *readingType in self.readingTypes) {
        if ([readingType.type isEqualToString:type]) {
            targetReadingType = readingType;
        }
    }
    NSLog(@"The type coming through for deletion is %@", type);
    NSFetchRequest *allData = [[NSFetchRequest alloc] init];
    [allData setEntity:[NSEntityDescription entityForName:NSStringFromClass([ReadingType class]) inManagedObjectContext:context]];
    NSPredicate *narrowSearchToType = [NSPredicate predicateWithFormat:@"type is Temperature"];
    [allData setPredicate:narrowSearchToType];
    NSLog(@"The name of the entity is %@", NSStringFromClass([ReadingType class]));
    [allData setIncludesPropertyValues:NO]; //only fetch the managedObjectID
    NSLog(@"In deleteOldData() and deleting objects");
    NSError *error = nil;
    
    //for (Reading * readings in allData.reading)
    NSArray *dataToBeDeleted = [context executeFetchRequest:allData error:&error];
    NSLog(@"Number of records in array = %d", [dataToBeDeleted count]);
    if (![dataToBeDeleted count]) return;
    //error handling goes here
    for (targetReadingType in dataToBeDeleted) {
        [context deleteObject:targetReadingType];
    }
    NSError *saveError = nil;
    [context save:&saveError];
    */
    
}


- (void)addData:(NSArray *)data forReadingType:(NSString *)type startTimestamp:(NSDate*)timeStamp interval:(NSInteger)interval context:(NSManagedObjectContext *)context {
	ReadingType *targetReadingType;
	for (ReadingType *readingType in self.readingTypes) {
		if ([readingType.type isEqualToString:type]) {
			targetReadingType = readingType;
		}
	}

	targetReadingType = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([ReadingType class]) inManagedObjectContext:context];
	[self addReadingTypesObject:targetReadingType];
	targetReadingType.type = type;

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
		
		if (self.startTimestamp) {
			reading.timestamp = [self.startTimestamp dateByAddingTimeInterval:interval*index];
		}
		else {
			reading.timestamp = [timeStamp dateByAddingTimeInterval:interval*index];
		}

		NSLog(@"Timestamp: %@, calculated from a start date of %@ and an interval of %li", reading.timestamp, timeStamp, (long)interval);
		index++;
	}
	NSError *saveError;
	[context save:&saveError];
	if (saveError) {
		NSLog(@"Error saving data import: %@", saveError);
	}
}

//Not used
- (void)addData:(NSArray *)data forReadingType:(NSString *)type context:(NSManagedObjectContext *)context {
    NSLog(@"In spare method for addData for TempoDevice");
	//[self addData:data forReadingType:type startTimestamp:timeStamp interval:interval context:context];
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
