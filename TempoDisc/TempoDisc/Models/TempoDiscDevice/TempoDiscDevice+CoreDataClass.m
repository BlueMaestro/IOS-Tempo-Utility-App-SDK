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

@implementation TempoDiscDevice

- (NSInteger)classID {
	return self.globalIdentifier.integerValue;
}

+ (TempoDiscDevice *)deviceWithName:(NSString *)name data:(NSDictionary *)data uuid:(nonnull NSString *)uuid context:(nonnull NSManagedObjectContext *)context {
	TempoDiscDevice *device = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([TempoDiscDevice class]) inManagedObjectContext:context];
	[device fillWithData:data name:name uuid:uuid];
	return device;
}

- (void)fillWithData:(NSDictionary *)advertisedData name:(NSString *)name uuid:(NSString *)uuid {
	[super fillWithData:advertisedData name:name uuid:uuid];
	NSData *custom = [advertisedData objectForKey:@"kCBAdvDataManufacturerData"];
	char * data = (char*)[custom bytes];
    NSUInteger dataLength = custom.length;
    for (NSUInteger i = 0; i < dataLength; i++) {
        Byte byte = 0;
        [custom getBytes:&byte range:NSMakeRange(i, 1)];
        //NSLog(@"Byte %lu is %02x", (unsigned long)i, byte);
        }
    Byte byte;
    [custom getBytes:&byte range:NSMakeRange(2, 1)];
	/**
	 *	Status bits
	 *	Not sure about data read
	 **/
    NSInteger version = byte;
    self.version = [NSString stringWithFormat:@"%ld", (long)version];
	self.battery = [NSDecimalNumber decimalNumberWithDecimal:@(data[3]).decimalValue];
	self.timerInterval = @(intValue(data[5], data[4]));
	self.intervalCounter = @(intValue(data[7], data[6]));
	self.currentTemperature = @(intValue(data[9], data[8]) / 10.f);
	self.currentHumidity = @(intValue(data[11], data[10]) / 10.f);
	self.dewPoint = [NSDecimalNumber decimalNumberWithDecimal:@(intValue(data[13], data[12]) / 10.f).decimalValue];
	self.mode = @(data[14]);
	if (self.mode.integerValue > 100) {
		self.isFahrenheit = @(YES);
	}
	else {
		self.isFahrenheit = @(NO);
	}
	self.numBreach = @(data[15]);
	
	//looks like there's no data for this in the broadcast
	float timeAtLastBreach = intValue(data[17], data[16]);
	float nameLength = data[18];
	
	
	
	if (self.version.integerValue == 22) {
        
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
	}
    
    if (self.version.integerValue == 23) {
		//verson 23 parse
        
        self.highestTemperature = @(intValue(data[custom.length-24], data[custom.length-25]) / 10.f);
        self.highestHumidity = @(intValue(data[custom.length-22], data[custom.length-23]) / 10.f);
        self.lowestTemperature = @(intValue(data[custom.length-20], data[custom.length-21]) / 10.f);
        self.lowestHumidity = @(intValue(data[custom.length-18], data[custom.length-19]) / 10.f);
        self.highestDayTemperature = @(intValue(data[custom.length-16], data[custom.length-17]) / 10.f);
        self.highestDayHumidity = @(intValue(data[custom.length-14], data[custom.length-15]) / 10.f);
        float highDewPointCalculation = ([self.highestDayTemperature floatValue] - ((100 - [self.highestDayHumidity floatValue]) /5));
        self.highestDayDew = @(highDewPointCalculation);
        //NSLog(@"highest day temperature is %f", [self.highestDayTemperature floatValue]);
        //NSLog(@"highest day humidity is %f", [self.highestDayHumidity floatValue]);
        //NSLog(@"dewpoint calculation is %f", dewPointCalculation);
        self.lowestDayTemperature = @(intValue(data[custom.length-12], data[custom.length-13]) / 10.f);
        self.lowestDayHumidity = @(intValue(data[custom.length-10], data[custom.length-11]) / 10.f);
        float lowDewPointCalculation = ([self.lowestDayTemperature floatValue] - ((100 - [self.lowestDayHumidity floatValue]) /5));
        self.lowestDayDew = @(lowDewPointCalculation);
        self.averageDayTemperature = @(intValue(data[custom.length-8], data[custom.length-9]) / 10.f);
        self.averageDayHumidity = @(intValue(data[custom.length-6], data[custom.length-7]) / 10.f);
        float avgDewPointCalculation = ([self.averageDayTemperature floatValue] - ((100 - [self.averageDayHumidity floatValue]) /5));
        self.averageDayDew = @(avgDewPointCalculation);

		self.globalIdentifier = @(data[custom.length-5]);
		
		//date digits, should be reverse from what is written, not sure about indexes
		NSNumber *fullValue = @( (((int) data[custom.length-1]) & 0xFF) | (((int) data[custom.length-2]) << 8) | (((int) data[custom.length-3]) << 16) | (((int) data[custom.length-4]) << 24) );
		
		/**
		 *	parse digits into date
		 *	yymmddhhmm
		 **/
        NSLog(@"Raw date number is %i", [fullValue intValue]);
        
        if (([fullValue intValue] != 0) || ([fullValue longValue] > 170000000000) || ([fullValue longValue] < 1900000000)) {
        
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


@end
