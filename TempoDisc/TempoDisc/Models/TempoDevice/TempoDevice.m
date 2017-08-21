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
#define BM_MODEL_DISC_13 0xD
#define BM_MODEL_DISC_22 0x16
#define BM_MODEL_DISC_23 0x17
#define BM_MODEL_DISC_27 0x1B
#define BM_MODEL_DISC_32 0x20
#define BM_MODEL_DISC_99 0x63
#define BM_MODEL_DISC_113 0x71

int getInt(char lsb,char msb)
{
	return (((int) lsb) & 0xFF) | (((int) msb) << 8);
}

@implementation TempoDevice

@dynamic peripheral;

- (NSInteger)classID {
	return 0;
}

// Insert code here to add functionality to your managed object subclass

+ (TempoDevice *)deviceWithName:(NSString *)name data:(NSDictionary *)data uuid:(nonnull NSString *)uuid context:(nonnull NSManagedObjectContext *)context {
    
	TempoDevice *device = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([TempoDevice class]) inManagedObjectContext:context];
    [device fillWithData:data name:name uuid:uuid];
	return device;
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

+ (BOOL)isTempoDisc13WithAdvertisementDate:(NSDictionary*)data {
    NSData *custom = [data objectForKey:@"kCBAdvDataManufacturerData"];
    //BlueMaestro device
    if (custom != nil)
    {
        unsigned char * d = (unsigned char*)[custom bytes];
        unsigned int manuf = d[1] << 8 | d[0];
        
        //Is this one of ours and is it version 13?
        if (manuf == MANUF_ID_BLUE_MAESTRO) {
            if (d[2] == BM_MODEL_DISC_13) {
                return YES;
            }
        }
    }
    return NO;
}




+ (BOOL)isTempoDisc22WithAdvertisementDate:(NSDictionary*)data {
    NSData *custom = [data objectForKey:@"kCBAdvDataManufacturerData"];
    //BlueMaestro device
    if (custom != nil)
    {
        unsigned char * d = (unsigned char*)[custom bytes];
        unsigned int manuf = d[1] << 8 | d[0];
        
        //Is this one of ours and is it version 22?
        if (manuf == MANUF_ID_BLUE_MAESTRO) {
            if (d[2] == BM_MODEL_DISC_22) {
                return YES;
            }
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
        
        //Is this one of ours and is it version 23?
        if (manuf == MANUF_ID_BLUE_MAESTRO) {
            if (d[2] == BM_MODEL_DISC_23) {
                return YES;
            }
        }
    }
    return NO;
}

+ (BOOL)isTempoDisc27WithAdvertisementDate:(NSDictionary*)data {
	NSData *custom = [data objectForKey:@"kCBAdvDataManufacturerData"];
	//BlueMaestro device
	if (custom != nil)
	{
		unsigned char * d = (unsigned char*)[custom bytes];
		unsigned int manuf = d[1] << 8 | d[0];
		
		//Is this one of ours and is it version 27?
		if (manuf == MANUF_ID_BLUE_MAESTRO) {
			if (d[2] == BM_MODEL_DISC_27) {
                return YES;
			}
		}
	}
	return NO;
}

+ (BOOL)isTempoDisc32WithAdvertisementDate:(NSDictionary*)data {
	NSData *custom = [data objectForKey:@"kCBAdvDataManufacturerData"];
	//BlueMaestro device
	if (custom != nil)
	{
		unsigned char * d = (unsigned char*)[custom bytes];
		unsigned int manuf = d[1] << 8 | d[0];
		
		//Is this one of ours and is it version 27?
		if (manuf == MANUF_ID_BLUE_MAESTRO) {
			if (d[2] == BM_MODEL_DISC_32) {
				return YES;
			}
		}
	}
	return NO;
}

+ (BOOL)isTempoDisc99WithAdvertisementDate:(NSDictionary*)data {
    NSData *custom = [data objectForKey:@"kCBAdvDataManufacturerData"];
    //BlueMaestro device
    if (custom != nil)
    {
        unsigned char * d = (unsigned char*)[custom bytes];
        unsigned int manuf = d[1] << 8 | d[0];
        
        //Is this one of ours and is it version 99?
        if (manuf == MANUF_ID_BLUE_MAESTRO) {
			if (d[2] == BM_MODEL_DISC_99) {
                return YES;
            }
        }
    }
    return NO;
}

+ (BOOL)isTempoDisc113WithAdvertisementDate:(NSDictionary*)data {
    NSData *custom = [data objectForKey:@"kCBAdvDataManufacturerData"];
    //BlueMaestro device
    if (custom != nil)
    {
        unsigned char * d = (unsigned char*)[custom bytes];
        unsigned int manuf = d[1] << 8 | d[0];
        
        //Is this one of ours and is it version 113?
        if (manuf == MANUF_ID_BLUE_MAESTRO) {
            if (d[2] == BM_MODEL_DISC_113) {
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
	self.lastDetected = [NSDate date];
	
	NSData *custom = [advertisedData objectForKey:@"kCBAdvDataManufacturerData"];
	
    bool isTempoDisc13 = false;
	bool isTempoDisc22 = false;
    bool isTempoDisc23 = false;
    bool isTempoDisc27 = false;
    bool isTempoDisc99 = false;
    bool isTempoDisc113 = false;
	NSString *deviceType = nil;
	
	//BlueMaestro device
	if (custom != nil) {
		unsigned char * d = (unsigned char*)[custom bytes];
		unsigned int manuf = d[1] << 8 | d[0];
		
		//Is this one of ours?
		if (manuf == MANUF_ID_BLUE_MAESTRO) {
            
            if (d[2] == BM_MODEL_DISC_13) {
                deviceType = @"TEMPO_DISC_13";
                isTempoDisc13 = true;
            }
            else if (d[2] == BM_MODEL_DISC_22) {
				deviceType = @"TEMPO_DISC_22";
				isTempoDisc22 = true;
			}
            else if (d[2] == BM_MODEL_DISC_23) {
                deviceType = @"TEMPO_DISC_23";
                isTempoDisc23 = true;
            }
            else if (d[2] == BM_MODEL_DISC_27) {
                deviceType = @"TEMPO_DISC_27";
                isTempoDisc27 = true;
            }
            else if (d[2] == BM_MODEL_DISC_99) {
                deviceType = @"PACIF-I V2";
                isTempoDisc99 = true;
            }
            else if (d[2] == BM_MODEL_DISC_113) {
                deviceType = @"TEMPO_DISC_113";
                isTempoDisc113 = true;
            }
		}
	}
    self.modelType = deviceType;
}

- (TempoDeviceType)deviceType {
    if  (self.version.integerValue == 13) return TempoDeviceType13;
    if  (self.version.integerValue == 22) return TempoDeviceType22;
    if  (self.version.integerValue == 23) return TempoDeviceType23;
    if  (self.version.integerValue == 27) return TempoDeviceType27;
    if  (self.version.integerValue == 99) return TempoDeviceType99;
    if  (self.version.integerValue == 113) return TempoDeviceType113;
    return TempoDeviceTypeUnknown;
}

- (void)deleteOldData:(NSString *)type context:(NSManagedObjectContext *)context {
    
    NSString *readingType;
    readingType = type;
    for (ReadingType *type in [TDSharedDevice sharedDevice].selectedDevice.readingTypes) {
        if ([type.type isEqualToString:readingType]) {
            [[TDSharedDevice sharedDevice].selectedDevice removeReadingTypesObject:type];
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

//		NSLog(@"Timestamp: %@, calculated from a start date of %@ and an interval of %li", reading.timestamp, timeStamp, (long)interval);
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

- (BOOL)hasDataForType:(NSString*)type {
	for (ReadingType *readingType in self.readingTypes) {
		if ([readingType.type isEqualToString:type]) {
			return YES;
		}
	}
	return NO;
}

@end
