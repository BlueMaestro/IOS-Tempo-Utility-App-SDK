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

+ (TempoDiscDevice *)deviceWithName:(NSString *)name data:(NSDictionary *)data uuid:(nonnull NSString *)uuid context:(nonnull NSManagedObjectContext *)context {
	TempoDiscDevice *device = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([TempoDiscDevice class]) inManagedObjectContext:context];
	[device fillWithData:data name:name uuid:uuid];
	return device;
}

- (void)fillWithData:(NSDictionary *)advertisedData name:(NSString *)name uuid:(NSString *)uuid {
	[super fillWithData:advertisedData name:name uuid:uuid];
	NSData *custom = [advertisedData objectForKey:@"kCBAdvDataManufacturerData"];
	char * data = (char*)[custom bytes];
	/**
	 *	Status bits
	 *	Not sure about data read
	 **/
	self.version = [NSNumber numberWithInt:data[2]].stringValue;
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
