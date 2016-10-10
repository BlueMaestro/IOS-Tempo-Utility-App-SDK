//
//  TDUARTDownloader.m
//  TempoDisc
//
//  Created by Nikola Misic on 10/5/16.
//  Copyright © 2016 BlueMaestro. All rights reserved.
//

#import "TDUARTDownloader.h"
#import <LGBluetooth/LGBluetooth.h>
#import "AppDelegate.h"

#define uartServiceUUIDString			@"6E400001-B5A3-F393-E0A9-E50E24DCCA9E"
#define uartRXCharacteristicUUIDString	@"6E400002-B5A3-F393-E0A9-E50E24DCCA9E"
#define uartTXCharacteristicUUIDString	@"6E400003-B5A3-F393-E0A9-E50E24DCCA9E"

#define kDataTerminationHeaderValue 58
#define kDataTerminationValue 46

#define kDeviceReconnectTimeout			2.0

#define kDeviceConnectTimeout			10.0

#define kDataStringTemperature			@"*logntemp"
#define kDataStringHumidity				@"*lognhumi"
#define kDataStringDewPoint				@"*logndewp"
#define kDataStringTransmitEnd			@"*qq"

typedef enum : NSInteger {
	DataDownloadTypeTemperature,
	DataDownloadTypeHumidity,
	DataDownloadTypeDewPoint,
	DataDownloadTypeFinish
} DataDownloadType;

@interface TDUARTDownloader()

@property (nonatomic, assign) BOOL didDisconnect;

@property (nonatomic, strong) NSDate* downloadStartTimestamp;
@property (nonatomic, strong) LGCharacteristic *writeCharacteristic;
@property (nonatomic, strong) NSString *dataToSend;

@property (nonatomic, assign) DataDownloadType currentDownloadType;

@property (nonatomic, strong) NSMutableArray *currentDataSamples;

@property (nonatomic, assign) NSInteger dataDownloadInterval;

@property (nonatomic, copy) DataDownloadCompletion completion;

@property (nonatomic, strong) NSNumber *logCounter;

@end

@implementation TDUARTDownloader

#pragma mark - Private methods

- (int)getIntLsb:(char)lsb msb:(char)msb {
	return (((int) lsb) & 0xFF) | (((int) msb) << 8);
}


- (void)writeData:(NSString*)data toCharacteristic:(LGCharacteristic*)characteristic {
	NSLog(@"Writing data: %@ to characteristic: %@", data, characteristic.UUIDString);
//	__weak typeof(self) weakself = self;
	[characteristic writeValue:[data dataUsingEncoding:NSUTF8StringEncoding] completion:^(NSError *error) {
		if (!error) {
			NSLog(@"Sucessefully wrote data to write characteristic");
		}
		else {
			NSLog(@"Error writing data to characteristic: %@", error);
		}
	}];
}

- (void)parseData:(NSData*)data {
	if (data.length == 15 ) {
		char * d = (char *)data.bytes;
		if (d[14] == kDataTerminationHeaderValue) {
			//header data, parse next point and dont impor
			NSInteger nextCounter = [self getIntLsb:d[5] msb:d[4]];
			_logCounter = @(nextCounter);
			return;
		}
	}
	NSInteger length = data.length;
	char * d = (char*)[data bytes];
	for (NSInteger i=0; i<length; i+=2) {
		if (d[i] == kDataTerminationValue) {
			//termination symbol found, abort data download and insert into database
			[self didFinishDownloadForType:_currentDownloadType];
			break;
		}
		else {
			NSInteger value = [self getIntLsb:d[i+1] msb:d[i]];
			[_currentDataSamples addObject:@[@(value / 10.f)]];
		}
	}
}

- (void)didFinishDownloadForType:(DataDownloadType)type {
	[self saveData:_currentDataSamples type:type];
	_currentDataSamples = [NSMutableArray array];
	
	//start loading next data type
	DataDownloadType downloadType = DataDownloadTypeTemperature;
	NSString* stringToWrite = @"";
	switch (type) {
		case DataDownloadTypeTemperature:
			downloadType = DataDownloadTypeHumidity;
			stringToWrite = [NSString stringWithFormat:@"%@%@", kDataStringHumidity, [(TempoDiscDevice*)[TDDefaultDevice sharedDevice].selectedDevice logCount]];
			break;
		case  DataDownloadTypeHumidity:
			downloadType = DataDownloadTypeDewPoint;
			stringToWrite = [NSString stringWithFormat:@"%@%@", kDataStringDewPoint, [(TempoDiscDevice*)[TDDefaultDevice sharedDevice].selectedDevice logCount]];
			break;
		case DataDownloadTypeDewPoint:
			downloadType = DataDownloadTypeFinish;
			stringToWrite = kDataStringTransmitEnd;
			[(TempoDiscDevice*)[TDDefaultDevice sharedDevice].selectedDevice setLogCount:_logCounter];
			if (_completion) {
				_completion(YES);
				_completion = nil;
			}
			break;
		case DataDownloadTypeFinish:
			downloadType = DataDownloadTypeFinish;
			break;
	}
	
	_currentDownloadType = downloadType;
	if (![SCHelper isNilOrEmpty:stringToWrite]) {
		[self writeData:stringToWrite toCharacteristic:_writeCharacteristic];
	}
	
}

- (void)saveData:(NSArray*)data type:(DataDownloadType)type {
	NSString *readingType;
	switch (type) {
		case DataDownloadTypeTemperature:
			readingType = @"Temperature";
			break;
		case DataDownloadTypeHumidity:
			readingType = @"Humidity";
			break;
		case DataDownloadTypeDewPoint:
			readingType = @"DewPoint";
  default:
			break;
	}
	if (readingType) {
		NSDate *timestamp = _downloadStartTimestamp;
		Reading *lastReading = [[[TDDefaultDevice sharedDevice].selectedDevice readingsForType:readingType] lastObject];
		if (lastReading) {
			timestamp = lastReading.timestamp;
		}
		[[TDDefaultDevice sharedDevice].selectedDevice addData:data forReadingType:readingType startTimestamp:timestamp interval:[(TempoDiscDevice*)[TDDefaultDevice sharedDevice].selectedDevice timerInterval].integerValue context:[(AppDelegate*)[UIApplication sharedApplication].delegate managedObjectContext]];
	}
	
}

#pragma mark - Public methods

+ (TDUARTDownloader *)shared {
	static TDUARTDownloader *singleton = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		singleton = [[TDUARTDownloader alloc] init];
	});
	return singleton;
}

- (void)downloadDataForDevice:(TempoDiscDevice *)device withCompletion:(void (^)(BOOL))completion {
	_currentDataSamples = [NSMutableArray array];
	_downloadStartTimestamp = [NSDate date];
	_completion = completion;
	NSLog(@"Connecting to device...");
	__weak typeof(self) weakself = self;
	[[TDDefaultDevice sharedDevice].selectedDevice.peripheral connectWithTimeout:kDeviceConnectTimeout completion:^(NSError *error) {
		weakself.didDisconnect = NO;
		if (!error) {
			NSLog(@"Connected to device");
			NSLog(@"Discovering device services...");
			[[TDDefaultDevice sharedDevice].selectedDevice.peripheral discoverServicesWithCompletion:^(NSArray *services, NSError *error2) {
				if (!error2) {
					NSLog(@"Discovered services");
					LGService *uartService;
					for (LGService* service in services) {
						if ([[service.UUIDString uppercaseString] isEqualToString:uartServiceUUIDString]) {
							uartService = service;
							NSLog(@"Found UART service: %@", service.UUIDString);
							NSLog(@"Discovering characteristics...");
							[service discoverCharacteristicsWithCompletion:^(NSArray *characteristics, NSError *error3) {
								if (!error3) {
									NSLog(@"Discovered characteristics");
									LGCharacteristic *readCharacteristic;
									for (LGCharacteristic *characteristic in characteristics) {
										if ([[characteristic.UUIDString uppercaseString] isEqualToString:uartTXCharacteristicUUIDString]) {
											NSLog(@"Found TX characteristic %@", characteristic.UUIDString);
											readCharacteristic = characteristic;
											/*CBMutableCharacteristic *noteCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:readCharacteristic.UUIDString] properties:CBCharacteristicPropertyNotify+CBCharacteristicPropertyRead
											 value:nil permissions:CBAttributePermissionsReadable|CBAttributePermissionsWriteable];
											 LGCharacteristic *characteristicForNotification = [[LGCharacteristic alloc] initWithCharacteristic:noteCharacteristic];*/
											NSLog(@"Subscribing for TX characteristic notifications");
											[characteristic setNotifyValue:YES completion:^(NSError *error4) {
												if (!error4) {
													NSLog(@"Subscribed for TX characteristic notifications");
												}
												else {
													NSLog(@"Error subscribing for TX characteristic: %@", error4);
												}
											} onUpdate:^(NSData *data, NSError *error5) {
												if (!error5) {
													//													[weakself addLogMessage:[NSString stringWithFormat:@"%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]] type:LogMessageTypeInbound];
													//TODO: Parse data
													[weakself parseData:data];
												}
												else {
													NSLog(@"Error on updating TX data: %@", error5);
												}
											}];
										}
										else if ([[characteristic.UUIDString uppercaseString] isEqualToString:uartRXCharacteristicUUIDString]) {
											NSLog(@"Found RX characteristic %@", characteristic.UUIDString);
											weakself.writeCharacteristic = characteristic;
										}
									}
									if (!readCharacteristic) {
										NSLog(@"Could not find TX characteristic");
									}
									if (!weakself.writeCharacteristic) {
										NSLog(@"Could not find RX characteristic");
									}
									if (weakself.writeCharacteristic) {
										[weakself writeData:[NSString stringWithFormat:@"%@%@", kDataStringTemperature, [(TempoDiscDevice*)[TDDefaultDevice sharedDevice].selectedDevice logCount]] toCharacteristic:weakself.writeCharacteristic];
										weakself.dataToSend = nil;
									}
								}
								else {
									NSLog(@"Error discovering device characteristics: %@", error3);
									completion(NO);
								}
							}];
							break;
						}
					}
					if (!uartService) {
						NSLog(@"Failed to found UART service");
						completion(NO);
					}
				}
				else {
					NSLog(@"Error discovering device services: %@", error2);
					completion(NO);
				}
			}];
		}
		else {
			NSLog(@"Error connecting to device: %@", error);
			completion(NO);
		}
	}];
}

@end
