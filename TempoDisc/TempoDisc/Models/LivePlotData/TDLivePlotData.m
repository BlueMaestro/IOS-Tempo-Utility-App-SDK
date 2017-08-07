//
//  TDLivePlotData.m
//  Tempo Utility
//
//  Created by Nikola Misic on 11/19/16.
//  Copyright © 2016 BlueMaestro. All rights reserved.
//

#import "TDLivePlotData.h"

@implementation TDLivePlotData

- (id)initWithString:(NSString *)dataString device:(TempoDevice*)device {
	if (self = [super init]) {
		if (device.version.integerValue == 22 || device.version.integerValue == 23) {
			//T25.4H56.7D16.8
			NSRange temperatureRange = [dataString rangeOfString:@"T"];
			NSRange humidityRange = [dataString rangeOfString:@"H"];
			NSRange dewpointRange = [dataString rangeOfString:@"D"];
			if (temperatureRange.location != NSNotFound) {
				NSString* temperatureString = [dataString substringWithRange:NSMakeRange(temperatureRange.location+1, humidityRange.location-1)];
				_temperature = @(temperatureString.floatValue);
				
				if (humidityRange.location != NSNotFound && dewpointRange.location != NSNotFound) {
					NSString* humidityString = [dataString substringWithRange:NSMakeRange(humidityRange.location+1, dewpointRange.location-humidityRange.location-1)];
					_humidity = @(humidityString.floatValue);
					
					NSString* dewPointString = [dataString substringWithRange:NSMakeRange(dewpointRange.location+1, dataString.length-dewpointRange.location-1)];
					_dewPoint = @(dewPointString.floatValue);
				}
			}
		}
		else if (device.version.integerValue == 13) {
			//T25.4
			NSRange temperatureRange = [dataString rangeOfString:@"T"];;
			if (temperatureRange.location != NSNotFound) {
				NSString* temperatureString = [dataString substringWithRange:NSMakeRange(temperatureRange.location+1, dataString.length-temperatureRange.location-1)];
				_temperature = @(temperatureString.floatValue);
			}
		}
		else if (device.version.integerValue == 27) {
			//T25.4H56.7P990.6
			NSRange temperatureRange = [dataString rangeOfString:@"T"];
			NSRange humidityRange = [dataString rangeOfString:@"H"];
			NSRange pressureRange = [dataString rangeOfString:@"P"];
			if (temperatureRange.location != NSNotFound) {
				NSString* temperatureString = [dataString substringWithRange:NSMakeRange(temperatureRange.location+1, humidityRange.location-1)];
				_temperature = @(temperatureString.floatValue);
				
				if (humidityRange.location != NSNotFound && pressureRange.location != NSNotFound) {
					NSString* humidityString = [dataString substringWithRange:NSMakeRange(humidityRange.location+1, pressureRange.location-humidityRange.location-1)];
					_humidity = @(humidityString.floatValue);
					
					NSString* pressureString = [dataString substringWithRange:NSMakeRange(pressureRange.location+1, dataString.length-pressureRange.location-1)];
					_pressure = @(pressureString.floatValue/10);
					
					_dewPoint = @(_temperature.floatValue-((100.-_humidity.floatValue)/5.));
				}
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

- (id)initWithString:(NSString *)dataString timestamp:(NSDate *)pointDate device:(TempoDevice*)device {
	self = [[TDLivePlotData alloc] initWithString:dataString device:device];
	_timestamp = pointDate;
	return self;
}

+ (BOOL)isValidData:(NSString*)dataString device:(TempoDevice*)device {
	if (device.version.integerValue == 22 || device.version.integerValue == 23) {
		NSRange temperatureRange = [dataString rangeOfString:@"T"];
		NSRange humidityRange = [dataString rangeOfString:@"H"];
		NSRange dewpointRange = [dataString rangeOfString:@"D"];
		return (temperatureRange.location != NSNotFound && humidityRange.location != NSNotFound && dewpointRange.location != NSNotFound);
	}
	else if (device.version.integerValue == 13) {
		NSRange temperatureRange = [dataString rangeOfString:@"T"];
		return (temperatureRange.location != NSNotFound);
	}
	else if (device.version.integerValue == 27) {
		NSRange temperatureRange = [dataString rangeOfString:@"T"];
		NSRange humidityRange = [dataString rangeOfString:@"H"];
		NSRange pressureRange = [dataString rangeOfString:@"P"];
		return (temperatureRange.location != NSNotFound && humidityRange.location != NSNotFound && pressureRange.location != NSNotFound);
	}
	else {
		return NO;
	}
}

@end
