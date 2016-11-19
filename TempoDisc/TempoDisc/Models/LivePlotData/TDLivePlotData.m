//
//  TDLivePlotData.m
//  Tempo Utility
//
//  Created by Nikola Misic on 11/19/16.
//  Copyright © 2016 BlueMaestro. All rights reserved.
//

#import "TDLivePlotData.h"

@implementation TDLivePlotData

- (id)initWithString:(NSString *)dataString {
	if (self = [super init]) {
		//T25.4H56.7D16.8
		NSRange temperatureRange = [dataString rangeOfString:@"T"];
		NSRange humidityRange = [dataString rangeOfString:@"H"];
		NSRange dewpointRange = [dataString rangeOfString:@"D"];
		if (temperatureRange.location != NSNotFound && humidityRange.location != NSNotFound && dewpointRange.location != NSNotFound) {
			NSString* temperatureString = [dataString substringWithRange:NSMakeRange(temperatureRange.location+1, humidityRange.location-1)];
			_temperature = @(temperatureString.floatValue);
			
			NSString* humidityString = [dataString substringWithRange:NSMakeRange(humidityRange.location+1, dewpointRange.location-humidityRange.location-1)];
			_humidity = @(humidityString.floatValue);
			
			NSString* dewPointString = [dataString substringWithRange:NSMakeRange(dewpointRange.location+1, dataString.length-dewpointRange.location-1)];
			_dewPoint = @(dewPointString.floatValue);
		}
		else {
			//test data
			_temperature = @(rand()%35);
			_humidity = @(rand()%100);
			_dewPoint = @(rand()%22);
		}
	}
	
	return self;
}

- (id)initWithString:(NSString *)dataString timestamp:(NSDate *)pointDate {
	self = [[TDLivePlotData alloc] initWithString:dataString];
	_timestamp = pointDate;
	return self;
}

+ (BOOL)isValidData:(NSString*)dataString {
	NSRange temperatureRange = [dataString rangeOfString:@"T"];
	NSRange humidityRange = [dataString rangeOfString:@"H"];
	NSRange dewpointRange = [dataString rangeOfString:@"D"];
	return (temperatureRange.location != NSNotFound && humidityRange.location != NSNotFound && dewpointRange.location != NSNotFound);
}

@end
