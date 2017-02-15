//
//  TempoDiscPressureDevice+CoreDataClass.m
//  
//
//  Created by Nikola Misic on 2/15/17.
//
//

#import "TempoDiscPressureDevice+CoreDataClass.h"

int intValueFrom(char lsb,char msb)
{
	return (((int) lsb) & 0xFF) | (((int) msb) << 8);
}

@implementation TempoDiscPressureDevice

- (void)fillWithData:(NSDictionary *)advertisedData name:(NSString *)name uuid:(NSString *)uuid {
	[super fillWithData:advertisedData name:name uuid:uuid];
	
	NSData *custom = [advertisedData objectForKey:@"kCBAdvDataManufacturerData"];
	unsigned char * data = (unsigned char*)[custom bytes];
	
	self.averageDayDew = @(intValueFrom(data[custom.length-1], data[custom.length-2]) / 10.f);
	self.pressure = [NSDecimalNumber decimalNumberWithDecimal:@(intValueFrom(data[13], data[12]) / 10.f).decimalValue];
	self.highestDayPressure = @(intValueFrom(data[custom.length-13], data[custom.length-14]) / 10.f);
	self.highestPressure = @0;
	self.lowestDayPressure = @(intValueFrom(data[custom.length-7], data[custom.length-8]) / 10.f);
	self.lowestPressure = @0;
}

@end
