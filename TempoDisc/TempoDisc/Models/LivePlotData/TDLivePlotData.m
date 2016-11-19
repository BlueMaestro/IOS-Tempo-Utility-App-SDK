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
		NSRange temperatureRange = [dataString rangeOfString:@"H"];
		if (temperatureRange.location != NSNotFound) {
			NSString* temperatureString = [dataString substringWithRange:NSMakeRange(temperatureRange.location-1, temperatureRange.length-2)];
			_temperature = @(temperatureString.floatValue);
			
			NSRange humidityRange = [dataString rangeOfString:@"D"];
			if (humidityRange.location != NSNotFound) {
				NSString* humidityString = [dataString substringWithRange:NSMakeRange(temperatureRange.location+temperatureRange.length, humidityRange.length-temperatureRange.length-2)];
				_humidity = @(humidityString.floatValue);
				
				NSString* dewPointString = [dataString substringWithRange:NSMakeRange(humidityRange.location+1, dataString.length-humidityRange.location + humidityRange.length)];
				_dewPoint = @(dewPointString.floatValue);
			}
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

@end
