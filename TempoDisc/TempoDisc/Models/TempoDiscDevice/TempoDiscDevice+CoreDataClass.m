//
//  TempoDiscDevice+CoreDataClass.m
//  
//
//  Created by Nikola Misic on 9/21/16.
//
//

#import "TempoDiscDevice+CoreDataClass.h"

int intValue(char lsb,char msb)
{
	return (((int) lsb) & 0xFF) | (((int) msb) << 8);
}

int largeIntValue(char lsb, char b3, char b2, char msb)
{
    return ((int) lsb) | (((int) b3) << 8) | (((int) b2) << 16) | (((int) msb) << 24);
    
}

@implementation TempoDiscDevice

- (NSInteger)classID {
	return self.globalIdentifier.integerValue;
}

+ (TempoDiscDevice *)deviceWithName:(NSString *)name data:(NSDictionary *)data uuid:(nonnull NSString *)uuid context:(nonnull NSManagedObjectContext *)context {
	TempoDiscDevice *device = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([self class]) inManagedObjectContext:context];
	[device fillWithData:data name:name uuid:uuid];
	return device;
}

- (void)fillWithData:(NSDictionary *)advertisedData name:(NSString *)name uuid:(NSString *)uuid {
	[super fillWithData:advertisedData name:name uuid:uuid];
	NSData *custom = [advertisedData objectForKey:@"kCBAdvDataManufacturerData"];
	unsigned char * data = (unsigned char*)[custom bytes];
    NSUInteger dataLength = custom.length;
    for (NSUInteger i = 0; i < dataLength; i++) {
        Byte byte = 0;
        [custom getBytes:&byte range:NSMakeRange(i, 1)];
        NSLog(@"Byte %lu is %02x", (unsigned long)i, byte);
        }
    Byte byte;
    [custom getBytes:&byte range:NSMakeRange(2, 1)];
	/**
	 *	Status bits
	 *	Not sure about data read
	 **/
    NSInteger version = byte;
    self.version = [NSNumber numberWithInt:version];
	self.battery = [NSDecimalNumber decimalNumberWithDecimal:@(data[3]).decimalValue];
	self.timerInterval = @(intValue(data[5], data[4]));
	self.intervalCounter = @(intValue(data[7], data[6]));
	self.currentTemperature = @(intValue(data[9], data[8]) / 10.f);
	self.currentHumidity = @(intValue(data[11], data[10]) / 10.f);
	self.mode = @(data[14]);
	if (self.mode.integerValue > 100) {
		self.isFahrenheit = @(1);
	}
	else {
		self.isFahrenheit = @(0);
	}
	self.numBreach = @(data[15]);

	
	if (self.version.integerValue == 22) {
        self.dewPoint = [NSDecimalNumber decimalNumberWithDecimal:@(intValue(data[13], data[12]) / 10.f).decimalValue];
        self.highestTemperature = @(intValue(data[custom.length-25], data[custom.length-26]) / 10.f);
        self.highestHumidity = @(intValue(data[custom.length-23], data[custom.length-24]) / 10.f);
        self.lowestTemperature = @(intValue(data[custom.length-21], data[custom.length-22]) / 10.f);
        self.lowestHumidity = @(intValue(data[custom.length-19], data[custom.length-20]) / 10.f);
        self.highestDayTemperature = @(intValue(data[custom.length-17], data[custom.length-18]) / 10.f);
        self.highestDayHumidity = @(intValue(data[custom.length-15], data[custom.length-16]) / 10.f);
		self.highestDayDew = @(intValue(data[custom.length-13], data[custom.length-14]) / 10.f);
		self.lowestDayTemperature = @(intValue(data[custom.length-11], data[custom.length-12]) / 10.f);
		self.lowestDayHumidity = @(intValue(data[custom.length-9], data[custom.length-10]) / 10.f);
		self.lowestDayDew = @(intValue(data[custom.length-7], data[custom.length-8]) / 10.f);
		self.averageDayTemperature = @(intValue(data[custom.length-5], data[custom.length-6]) / 10.f);
		self.averageDayHumidity = @(intValue(data[custom.length-3], data[custom.length-4]) / 10.f);
		self.averageDayDew = @(intValue(data[custom.length-1], data[custom.length-2]) / 10.f);
        if (self.mode.integerValue > 100) {
            self.highestDayDew = @([self convertedValue:[self.highestDayDew floatValue]]);
            self.lowestDayDew = @([self convertedValue:[self.lowestDayDew floatValue]]);
            self.averageDayDew = @([self convertedValue:[self.averageDayDew floatValue]]);
        }
	}
    
    if (self.version.integerValue == 23) {
        self.dewPoint = [NSDecimalNumber decimalNumberWithDecimal:@(intValue(data[13], data[12]) / 10.f).decimalValue];
        self.highestTemperature = @(intValue(data[custom.length-24], data[custom.length-25]) / 10.f);
        self.highestHumidity = @(intValue(data[custom.length-22], data[custom.length-23]) / 10.f);
        self.lowestTemperature = @(intValue(data[custom.length-20], data[custom.length-21]) / 10.f);
        self.lowestHumidity = @(intValue(data[custom.length-18], data[custom.length-19]) / 10.f);
        self.highestDayTemperature = @(intValue(data[custom.length-16], data[custom.length-17]) / 10.f);
        self.highestDayHumidity = @(intValue(data[custom.length-14], data[custom.length-15]) / 10.f);
        float highDewPointCalculation = (float)([self.highestDayTemperature floatValue] - ((100 - [self.highestDayHumidity floatValue]) /5));
        self.highestDayDew = @(highDewPointCalculation);
        self.lowestDayTemperature = @(intValue(data[custom.length-12], data[custom.length-13]) / 10.f);
        self.lowestDayHumidity = @(intValue(data[custom.length-10], data[custom.length-11]) / 10.f);
        float lowDewPointCalculation = (float)([self.lowestDayTemperature floatValue] - ((100 - [self.lowestDayHumidity floatValue]) /5));
        self.lowestDayDew = @(lowDewPointCalculation);
        self.averageDayTemperature = @(intValue(data[custom.length-8], data[custom.length-9]) / 10.f);
        self.averageDayHumidity = @(intValue(data[custom.length-6], data[custom.length-7]) / 10.f);
        float avgDewPointCalculation = (float)([self.averageDayTemperature floatValue] - ((100 - [self.averageDayHumidity floatValue]) /5));
        self.averageDayDew = @(avgDewPointCalculation);
        if (self.mode.integerValue > 100) {
            self.highestDayDew = @([self convertedValue:[self.highestDayDew floatValue]]);
            self.lowestDayDew = @([self convertedValue:[self.lowestDayDew floatValue]]);
            self.averageDayDew = @([self convertedValue:[self.averageDayDew floatValue]]);
        }

		self.globalIdentifier = @(data[custom.length-5]);
		
        const unsigned char dateBytes[] = {data[custom.length-4], data[custom.length-3], data[custom.length-2], data[custom.length-1]};
        NSData *dateValues = [NSData dataWithBytes:dateBytes length:4];
		//date digits, should be reverse from what is written, not sure about indexes
        unsigned dateValueRawValue = CFSwapInt32BigToHost(*(int*)([dateValues bytes]));
        NSLog(@"Trying to reverse endian, value is %u", dateValueRawValue);
        
        NSNumber *fullValue = [NSNumber numberWithUnsignedInt:dateValueRawValue];
        self.referenceDateRawNumber = fullValue;
        long lowDate = 1700000000; //1 January 2017
        long highDate = 1900000000; //1 January 2019
        if (([fullValue intValue] != 0) || ([fullValue longValue] > lowDate) || ([fullValue longValue] < highDate)) {
		NSInteger minutes = fullValue.integerValue % 100;
		NSInteger hours = (fullValue.integerValue/100) % 100;
		NSInteger days = (fullValue.integerValue/10000) % 100;
		NSInteger months = (fullValue.integerValue/1000000) % 100;
		NSInteger years = (fullValue.integerValue/100000000) % 100;
		
		NSCalendar* calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
		NSDateComponents *components = [[NSDateComponents alloc] init];
		//MIN is for testing purposes as returning invalid values provides an unexpected date, can be removed once date parse is valid
		components.minute = MIN(minutes, 60);
		components.hour = MIN(hours, 24);
		components.day = MIN(days, 31);
		components.month = MIN(months, 12);
		components.year = years+2000;//add century as its only last 2 digits
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = @"yyyy MMM dd HH:mm";
        NSDate *date = [calendar dateFromComponents:components];
            
		self.startTimestamp = [calendar dateFromComponents:components];
            NSLog(@"%@", [dateFormatter stringFromDate:date]);
            
        }
		
		NSLog(@"Parsed version 23 data");
	}
    
   
	
	/*NSLog(@"---------------------------------------------------------------");
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
	 NSLog(@"---------------------------------------------------------------");*/
}

-(float) convertedValue:(float)preconversion {
    float converted = ((preconversion * 1.8) + 32);
    return converted;
    
}

//This simply takes the devices current readings and populates a persistent store for that data.
- (void)fillDataForPersistentStore :(TDTempoDisc *)device {
	self.peripheral = device.peripheral;
	
	self.uuid = device.uuid;
	self.name = device.name;
	self.battery = [NSDecimalNumber decimalNumberWithDecimal:device.battery.decimalValue];
	self.modelType = device.modelType;
    NSLog(@"Version is %@", device.version);
    self.version = device.version;
	self.currentTemperature = device.currentTemperature;
	self.currentMinTemperature = device.currentMinTemperature;
	self.currentMaxTemperature = device.currentMaxTemperature;
	self.currentHumidity = device.currentHumidity;
	self.currentPressure = device.currentPressure;
	self.currentPressureData = device.currentPressureData;
	self.lastDownload = device.lastDownload;
	self.isBlueMaestroDevice = device.isBlueMaestroDevice;
	self.isFahrenheit = device.isFahrenheit;
	self.inRange = device.inRange;
	self.startTimestamp = device.startTimestamp;
	self.lastDetected = device.lastDetected;
	self.timerInterval = device.timerInterval;
	self.intervalCounter = device.intervalCounter;
	self.dewPoint = [NSDecimalNumber decimalNumberWithDecimal:device.dewPoint.decimalValue];
	self.mode = device.mode;
	self.numBreach = device.numBreach;
	self.highestTemperature = device.highestTemperature;
	self.highestHumidity = device.highestHumidity;
	self.highestDew = device.highestDew;
	self.lowestTemperature = device.lowestTemperature;
	self.lowestHumidity = device.lowestHumidity;
	self.lowestDew = device.lowestDew;
	self.highestDayTemperature = device.highestDayTemperature;
	self.highestDayHumidity = device.highestDayHumidity;
	self.highestDayDew = device.highestDayDew;
	self.lowestDayTemperature = device.lowestDayTemperature;
	self.lowestDayHumidity = device.lowestDayHumidity;
	self.lowestDayDew = device.lowestDayDew;
	self.averageDayTemperature = device.averageDayTemperature;
	self.averageDayHumidity = device.averageDayHumidity;
	self.averageDayDew = device.averageDayDew;
	self.logCount = device.logCount;
	self.referenceDateRawNumber = device.referenceDateRawNumber;
	self.globalIdentifier = device.globalIdentifier;
	self.averageDayPressure = device.averageDayPressure;
	self.pressure = device.pressure;
	self.highestDayPressure = device.highestDayPressure;
	self.highestPressure = device.highestPressure;
	self.lowestDayPressure = device.lowestDayPressure;
	self.lowestPressure = device.lowestPressure;
	
}

@end
