//
//  TDTempoDisc.m
//  Tempo Utility
//
//  Created by Nikola Misic on 2/22/17.
//  Copyright © 2017 BlueMaestro. All rights reserved.
//

#import "TDTempoDisc.h"
#define MANUF_ID_BLUE_MAESTRO 0x0133
#define BM_MODEL_DISC_22 0x16
#define BM_MODEL_DISC_23 0x17
#define BM_MODEL_DISC_27 0x1B
#define BM_MODEL_DISC_99 0x63

@implementation TDTempoDisc

- (BOOL)isEqual:(id)object {
	if ([object isKindOfClass:[TDTempoDisc class]] && [[(TDTempoDisc*)object uuid] isEqualToString:self.uuid]) {
		return YES;
	}
	else {
		return NO;
	}
}

- (int)intValueLsb:(char)lsb msb:(char)msb {
	return (((int) lsb) & 0xFF) | (((int) msb) << 8);
}

-(float) convertedValue:(float)preconversion {
	float converted = ((preconversion * 1.8) + 32);
	return converted;
	
}

- (void)fillWithData:(NSDictionary *)advertisedData name:(NSString *)name uuid:(NSString *)uuid {
	NSData *manufacturerData = [advertisedData objectForKey:@"kCBAdvDataManufacturerData"];
	unsigned char * data = (unsigned char*)[manufacturerData bytes];
	NSUInteger manufacturerDataLength = manufacturerData.length;
    
    //This for loop is to print out each byte to NSLog for debug purposes
    /*
	for (NSUInteger i = 0; i < dataLength; i++) {
		Byte byte = 0;
		[manufacturerData getBytes:&byte range:NSMakeRange(i, 1)];
		//NSLog(@"Byte %lu is %02x", (unsigned long)i, byte);
	}
     */

	
	//Check whether BlueMaestro device and if so what version it is
	if (manufacturerData != nil) {
		unsigned char * d = (unsigned char*)[manufacturerData bytes];
		unsigned int manuf = d[1] << 8 | d[0];
		
		//Is this one of ours?
		if (manuf == MANUF_ID_BLUE_MAESTRO) {
			self.isBlueMaestroDevice = @(YES);
            
            //Is this one of our supported models for this app?
			if (d[2] == BM_MODEL_DISC_22) {
				self.modelType = @"TEMPO_DISC_22";
                self.version = [NSNumber numberWithInteger:22];
			}
			else if (d[2] == BM_MODEL_DISC_23) {
				self.modelType = @"TEMPO_DISC_23";
                self.version = [NSNumber numberWithInteger:23];
			}
			else if (d[2] == BM_MODEL_DISC_27) {
				self.modelType = @"TEMPO_DISC_27";
                self.version = [NSNumber numberWithInteger:27];
			}
            else if (d[2] == BM_MODEL_DISC_99) {
                self.modelType = @"PACIF-I V2";
                self.version = [NSNumber numberWithInteger:99];
            }
		} else {
            
            //Not a supported model
			return;
		}
	} else {
        //Not one of ours
		self.isBlueMaestroDevice = @(NO);
		return;
	}
    
    /**
    *	Version 22
    *
    **/	
	if (self.version.integerValue == 22) {
        
        //Variables not parsed
        self.uuid = uuid;
        self.name = advertisedData[@"kCBAdvDataLocalName"];
        self.lastDetected = [NSDate date];
        
        //Advertisement packet
        self.version = @(data[2]);
        self.battery = [NSDecimalNumber decimalNumberWithDecimal:@(data[3]).decimalValue];
        self.timerInterval = @([self intValueLsb:data[5] msb:data[4]]);
        self.intervalCounter = @([self intValueLsb:data[7] msb:data[6]]);
        self.currentTemperature = @([self intValueLsb:data[9] msb:data[8]] / 10.f);
        self.currentHumidity = @([self intValueLsb:data[11] msb:data[10]] / 10.f);
        self.dewPoint = @([self intValueLsb:data[13] msb:data[12]] / 10.f);
        self.mode = @(data[14]);
        if (self.mode.integerValue > 100) {
            self.isFahrenheit = @(1);
        }
        else {
            self.isFahrenheit = @(0);
        }
        self.numBreach = @(data[15]);
		
        //Scan response packet
		self.highestTemperature = @([self intValueLsb:data[manufacturerDataLength-25] msb:data[manufacturerDataLength-26]] / 10.f);
		self.highestHumidity = @([self intValueLsb:data[manufacturerDataLength-23] msb:data[manufacturerDataLength-24]] / 10.f);
		self.lowestTemperature = @([self intValueLsb:data[manufacturerDataLength-21] msb:data[manufacturerDataLength-22]] / 10.f);
		self.lowestHumidity = @([self intValueLsb:data[manufacturerDataLength-19] msb:data[manufacturerDataLength-20]] / 10.f);
		self.highestDayTemperature = @([self intValueLsb:data[manufacturerDataLength-17] msb:data[manufacturerDataLength-18]] / 10.f);
		self.highestDayHumidity = @([self intValueLsb:data[manufacturerDataLength-15] msb:data[manufacturerDataLength-16]] / 10.f);
		self.highestDayDew = @([self intValueLsb:data[manufacturerDataLength-13] msb:data[manufacturerDataLength-14]] / 10.f);
		self.lowestDayTemperature = @([self intValueLsb:data[manufacturerDataLength-11] msb:data[manufacturerDataLength-12]] / 10.f);
		self.lowestDayHumidity = @([self intValueLsb:data[manufacturerDataLength-9] msb:data[manufacturerDataLength-10]] / 10.f);
		self.lowestDayDew = @([self intValueLsb:data[manufacturerDataLength-7] msb:data[manufacturerDataLength-8]] / 10.f);
		self.averageDayTemperature = @([self intValueLsb:data[manufacturerDataLength-5] msb:data[manufacturerDataLength-6]] / 10.f);
		self.averageDayHumidity = @([self intValueLsb:data[manufacturerDataLength-3] msb:data[manufacturerDataLength-4]] / 10.f);
		self.averageDayDew = @([self intValueLsb:data[manufacturerDataLength-1] msb:data[manufacturerDataLength-2]] / 10.f);
		if (self.mode.integerValue > 100) {
			self.highestDayDew = @([self convertedValue:[self.highestDayDew floatValue]]);
			self.lowestDayDew = @([self convertedValue:[self.lowestDayDew floatValue]]);
			self.averageDayDew = @([self convertedValue:[self.averageDayDew floatValue]]);
		}
	}
    
    /**
     *	Version 23
     *
     **/
	
	if (self.version.integerValue == 23) {
        
        //Variables not parsed
        self.uuid = uuid;
        self.name = advertisedData[@"kCBAdvDataLocalName"];
        self.lastDetected = [NSDate date];
        self.version = @(data[2]);
        
        //Advertisement packet
        self.battery = [NSDecimalNumber decimalNumberWithDecimal:@(data[3]).decimalValue];
        self.timerInterval = @([self intValueLsb:data[5] msb:data[4]]);
        self.intervalCounter = @([self intValueLsb:data[7] msb:data[6]]);
        self.currentTemperature = @([self intValueLsb:data[9] msb:data[8]] / 10.f);
        self.currentHumidity = @([self intValueLsb:data[11] msb:data[10]] / 10.f);
        self.dewPoint = @([self intValueLsb:data[13] msb:data[12]] / 10.f);
        self.mode = @(data[14]);
        if (self.mode.integerValue > 100) {
            self.isFahrenheit = @(1);
        }
        else {
            self.isFahrenheit = @(0);
        }
        self.numBreach = @(data[15]);
		
    
        //Scan response packet
		self.highestTemperature = @([self intValueLsb:data[manufacturerDataLength-24] msb:data[manufacturerDataLength-25]] / 10.f);
		self.highestHumidity = @([self intValueLsb:data[manufacturerDataLength-22] msb:data[manufacturerDataLength-23]] / 10.f);
		self.lowestTemperature = @([self intValueLsb:data[manufacturerDataLength-20] msb:data[manufacturerDataLength-21]] / 10.f);
		self.lowestHumidity = @([self intValueLsb:data[manufacturerDataLength-18] msb:data[manufacturerDataLength-19]] / 10.f);
		self.highestDayTemperature = @([self intValueLsb:data[manufacturerDataLength-16] msb:data[manufacturerDataLength-17]] / 10.f);
		self.highestDayHumidity = @([self intValueLsb:data[manufacturerDataLength-14] msb:data[manufacturerDataLength-15]] / 10.f);
		float highDewPointCalculation = (float)([self.highestDayTemperature floatValue] - ((100 - [self.highestDayHumidity floatValue]) /5));
		self.highestDayDew = @(highDewPointCalculation);
		self.lowestDayTemperature = @([self intValueLsb:data[manufacturerDataLength-12] msb:data[manufacturerDataLength-13]] / 10.f);
		self.lowestDayHumidity = @([self intValueLsb:data[manufacturerDataLength-10] msb:data[manufacturerDataLength-11]] / 10.f);
		float lowDewPointCalculation = (float)([self.lowestDayTemperature floatValue] - ((100 - [self.lowestDayHumidity floatValue]) /5));
		self.lowestDayDew = @(lowDewPointCalculation);
		self.averageDayTemperature = @([self intValueLsb:data[manufacturerDataLength-8] msb:data[manufacturerDataLength-9]] / 10.f);
		self.averageDayHumidity = @([self intValueLsb:data[manufacturerDataLength-6] msb:data[manufacturerDataLength-7]] / 10.f);
		float avgDewPointCalculation = (float)([self.averageDayTemperature floatValue] - ((100 - [self.averageDayHumidity floatValue]) /5));
		self.averageDayDew = @(avgDewPointCalculation);
		if (self.mode.integerValue > 100) {
			self.highestDayDew = @([self convertedValue:[self.highestDayDew floatValue]]);
			self.lowestDayDew = @([self convertedValue:[self.lowestDayDew floatValue]]);
			self.averageDayDew = @([self convertedValue:[self.averageDayDew floatValue]]);
		}
		
		self.globalIdentifier = @(data[manufacturerDataLength-5]);
        NSLog(@"Global identifier is %@", self.globalIdentifier);
		
		const unsigned char dateBytes[] = {data[manufacturerDataLength-4], data[manufacturerDataLength-3], data[manufacturerDataLength-2], data[manufacturerDataLength-1]};
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
    
    /**
     *	Version 99 PACIF-I V2
     *
     **/
	
    if (self.version.integerValue == 99) {
        self.uuid = uuid;
        self.name = advertisedData[@"kCBAdvDataLocalName"];
        self.lastDetected = [NSDate date];
        self.battery = [NSDecimalNumber decimalNumberWithDecimal:@(data[3]).decimalValue];
        self.timerInterval = @([self intValueLsb:data[5] msb:data[4]]);
        self.intervalCounter = @([self intValueLsb:data[7] msb:data[6]]);
        self.currentTemperature = @([self intValueLsb:data[9] msb:data[8]] / 10.f);
        
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

- (TempoDeviceType)deviceType {
	if  (self.version.integerValue == 22) return TempoDeviceType22;
    if  (self.version.integerValue == 23) return TempoDeviceType23;
    if  (self.version.integerValue == 27) return TempoDeviceType27;
    if  (self.version.integerValue == 99) return TempoDeviceType99;
    return TempoDeviceTypeUnknown;
}

@end
