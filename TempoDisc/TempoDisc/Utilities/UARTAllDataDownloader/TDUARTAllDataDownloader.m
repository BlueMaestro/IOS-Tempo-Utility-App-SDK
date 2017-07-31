//
//  TDUARTAllDataDownloader.m
//  Tempo Utility
//
//  Created by Nikola Misic on 10/13/16.
//  Copyright © 2016 BlueMaestro. All rights reserved.
//

#import "TDUARTAllDataDownloader.h"

#import <LGBluetooth/LGBluetooth.h>
#import "AppDelegate.h"

#define uartServiceUUIDString			@"6E400001-B5A3-F393-E0A9-E50E24DCCA9E"
#define uartRXCharacteristicUUIDString	@"6E400002-B5A3-F393-E0A9-E50E24DCCA9E"
#define uartTXCharacteristicUUIDString	@"6E400003-B5A3-F393-E0A9-E50E24DCCA9E"

#define kDataTerminationHeaderValue 58
#define kDataTerminationValue 46
#define kDataTerminationBetweenValue 44

#define kDeviceConnectTimeout			20.0
#define kDeviceReConnectTimeout			8.0
#define kDeviceDataParseTimeout			20.0

#define kDataDownloadString				@"*logall"

typedef enum : NSInteger {
	DataDownloadTypeTemperature,
	DataDownloadTypeHumidity,
	DataDownloadTypeDewPoint,
	DataDownloadTypePressure,
	DataDownloadTypeFirstMovement,
	DataDownloadTypeSecondMovement,
	DataDownloadTypeOpenClose,
	DataDownloadTypeLux,
	DataDownloadTypeFinish
} DataDownloadType;

@interface TDUARTAllDataDownloader()

@property (nonatomic, assign) BOOL didDisconnect;

@property (nonatomic, strong) NSDate* downloadStartTimestamp;
@property (nonatomic, strong) LGCharacteristic *writeCharacteristic;
@property (nonatomic, strong) NSString *dataToSend;

@property (nonatomic, assign) DataDownloadType currentDownloadType;

@property (nonatomic, strong) NSMutableArray *currentDataSamples;

@property (nonatomic, assign) NSInteger dataDownloadInterval;

@property (nonatomic, copy) DataDownloadCompletion completion;
@property (nonatomic, copy) DataDownloadCompletion finish;

@property (nonatomic, strong) NSNumber *logCounter;

@property (nonatomic, assign) NSInteger deviceVersion;

@property (nonatomic, assign) NSInteger totalCurrentSample;

@property (nonatomic, strong) NSTimer *timerDataParseTimeout;

@end

@implementation TDUARTAllDataDownloader

#pragma mark - Private methods

- (void)fillDewpointsDataForDevice:(TempoDevice*)device {
	NSArray *temperatureReadings = [device readingsForType:@"Temperature"];
	NSArray *humidityReadings = [device readingsForType:@"Humidity"];
	NSMutableArray *dewPointsValues = [NSMutableArray array];
	for (NSInteger i=0; i<MIN(temperatureReadings.count, humidityReadings.count); i++) {
		Reading *temperatureReading = temperatureReadings[i];
		Reading *humidityReading = humidityReadings[i];
		
		//min, avg, max
		[dewPointsValues addObject:@[@(temperatureReading.minValue.floatValue-((100.-humidityReading.minValue.floatValue)/5.)),
									 @(temperatureReading.avgValue.floatValue-((100.-humidityReading.avgValue.floatValue)/5.)),
									 @(temperatureReading.maxValue.floatValue-((100.-humidityReading.maxValue.floatValue)/5.))]];
	}
	
	[[TDSharedDevice sharedDevice].selectedDevice addData:dewPointsValues forReadingType:@"DewPoint" startTimestamp:[(Reading*)[temperatureReadings firstObject] timestamp] interval:[(TempoDiscDevice*)[TDSharedDevice sharedDevice].selectedDevice timerInterval].integerValue context:[(AppDelegate*)[UIApplication sharedApplication].delegate managedObjectContext]];
}

- (int)getIntLsb:(char)lsb msb:(char)msb {
	return (((int) lsb) & 0xFF) | (((int) msb) << 8);
}


- (void)writeData:(NSString*)data toCharacteristic:(LGCharacteristic*)characteristic {
	NSLog(@"Writing data: %@ to characteristic: %@", data, characteristic.UUIDString);
	//	__weak typeof(self) weakself = self;
	[characteristic writeValue:[data dataUsingEncoding:NSUTF8StringEncoding] completion:^(NSError *error) {
		if (!error) {
			NSLog(@"Sucessefully wrote \"%@\" data to write characteristic", data);
			if (_finish) {
				_finish(YES);
			}
		}
		else {
			NSLog(@"Error writing data to characteristic: %@", error);
			if (_finish) {
				_finish(NO);
			}
		}
	}];
}

- (void)parseData:(NSData*)data {
	[_timerDataParseTimeout invalidate];
	_timerDataParseTimeout = nil;
	_timerDataParseTimeout = [NSTimer timerWithTimeInterval:kDeviceDataParseTimeout target:self selector:@selector(handleTimeout:) userInfo:nil repeats:NO];
	[[NSRunLoop mainRunLoop] addTimer:_timerDataParseTimeout forMode:NSDefaultRunLoopMode];
	NSLog(@"data received: %@", data);
	if (data.length == 15 ) {
		NSLog(@"Header data received: %@", data);
		char * d = (char *)data.bytes;
		if (d[14] == kDataTerminationHeaderValue) {
			NSInteger sendLogPointer = [self getIntLsb:d[1] msb:d[0]];
			NSInteger sendRecordsNeeded = [self getIntLsb:d[3] msb:d[2]];
			NSInteger sendGlobalLogCount = [self getIntLsb:d[5] msb:d[4]];
			NSInteger sendRecordSize = [self getIntLsb:d[7] msb:d[6]];
			NSInteger mode = d[8];
			NSInteger alarmFlag = d[9];
			NSInteger alarm1Value = [self getIntLsb:d[11] msb:d[10]];
			NSInteger alarm2Value = [self getIntLsb:d[13] msb:d[14]];
			NSLog(@"---------------------------------------");
			NSLog(@"Header data parsed");
			NSLog(@"send_log_pointer : %ld", (long)sendLogPointer);
			NSLog(@"send_records_needed: %ld", (long)sendRecordsNeeded);
			NSLog(@"send_global_log_count: %ld", (long)sendGlobalLogCount);
			NSLog(@"send_record_size: %ld", (long)sendRecordSize);
			NSLog(@"mode: %ld", (long)mode);
			NSLog(@"alarm_flag_for_header: %ld", (long)alarmFlag);
			NSLog(@"alarm_1_value: %ld", (long)alarm1Value);
			NSLog(@"alarm_2_value: %ld", (long)alarm2Value);
			//header data, parse next point and dont impor
			NSInteger nextCounter = [self getIntLsb:d[5] msb:d[4]];
			_logCounter = @(nextCounter);
			_totalCurrentSample = sendGlobalLogCount;
			
			switch (_currentDownloadType) {
				case DataDownloadTypeTemperature:
					[self notifyUpdateForProgress:0.0];
					break;
				case DataDownloadTypeHumidity:
					[self notifyUpdateForProgress:1/3.0];
					break;
				case DataDownloadTypePressure:
				case DataDownloadTypeDewPoint:
					[self notifyUpdateForProgress:2/3.0];
					break;
				case DataDownloadTypeFirstMovement:
					[self notifyUpdateForProgress:0.5];
					break;
				case DataDownloadTypeSecondMovement:
					[self notifyUpdateForProgress:1.0];
					break;
				case DataDownloadTypeOpenClose:
					[self notifyUpdateForProgress:1.0];
					break;
				case DataDownloadTypeLux:
					[self notifyUpdateForProgress:1.0];
					break;
				case DataDownloadTypeFinish:
					break;
			}
			
			return;
		}
	}
	float baseProgress = 0.0;
	NSInteger length = data.length;
	char * d = (char*)[data bytes];
	for (NSInteger i=0; i<length; i+= (_deviceVersion == 62 ? 4 : 2)) {
		if ((d[i] == kDataTerminationBetweenValue && d[i+1] == kDataTerminationBetweenValue) ||
			((_currentDownloadType == DataDownloadTypeDewPoint || _currentDownloadType == DataDownloadTypePressure) && d[i] == kDataTerminationValue) ||
			(_deviceVersion == 13 && d[i] == kDataTerminationValue) ||
			(_deviceVersion == 32 && d[i] == kDataTerminationValue) ||
			(_deviceVersion == 52 && d[i] == kDataTerminationValue)||
			(_deviceVersion == 62 && d[i] == kDataTerminationValue)) {
			//termination symbol found, abort data download and insert into database
			NSLog(@"Termination symbol recognized.");
			[self didFinishDownloadForType:_currentDownloadType];
			break;
		}
		else {
			NSString *type = @"UNKNOWN";
			
			switch (_currentDownloadType) {
				case DataDownloadTypeTemperature:
					type = @"T";
					baseProgress = 0.0;
					break;
				case DataDownloadTypeHumidity:
					baseProgress = 1/3.0;
					type = @"H";
					break;
				case DataDownloadTypePressure:
					type = @"P";
					baseProgress = 2/3.0;
					break;
				case DataDownloadTypeDewPoint:
					type = @"D";
					baseProgress = 2/3.0;
					break;
				case DataDownloadTypeFirstMovement:
					type = @"FM";
					baseProgress = 0;
					break;
				case DataDownloadTypeSecondMovement:
					type = @"SM";
					baseProgress = 0.5;
					break;
				case DataDownloadTypeOpenClose:
					type = @"OC";
					baseProgress = 0.0;
					break;
				case DataDownloadTypeLux:
					type = @"LX";
					baseProgress = 0.0;
				case DataDownloadTypeFinish:
					break;
			}
			NSLog(@"sample raw value: %@. Record number: %lu. Type: %@", [data subdataWithRange:NSMakeRange(i, 2)], (unsigned long)_currentDataSamples.count, type);
			NSInteger value = 0;
			if (_deviceVersion == 62) {
				const unsigned char levelBytes[] = {d[i], d[i+1], d[i+2], d[i+3]};
				NSData *levelValues = [NSData dataWithBytes:levelBytes length:4];
				unsigned levelValueRawValue = CFSwapInt32BigToHost(*(int*)([levelValues bytes]));
				value = [NSNumber numberWithUnsignedInt:levelValueRawValue].integerValue;
			}
			else {
				value = [self getIntLsb:d[i+1] msb:d[i]];
			}
			NSLog(@"Sample parsed value: %ld", (long)value);
			[_currentDataSamples addObject:@[@(value / 10.f)]];
			if (_deviceVersion == 13 || _deviceVersion == 52 || _deviceVersion == 62) {
				[self notifyUpdateForProgress:baseProgress+(_totalCurrentSample == 0 ? 0 : (float)_currentDataSamples.count / (float)_totalCurrentSample)];
			}
			else if (_deviceVersion == 32) {
				[self notifyUpdateForProgress:baseProgress+(_totalCurrentSample == 0 ? 0 : (float)_currentDataSamples.count / (float)_totalCurrentSample)*0.5];
			}
			else {
				[self notifyUpdateForProgress:baseProgress+(_totalCurrentSample == 0 ? 0 : (float)_currentDataSamples.count / (float)_totalCurrentSample)*0.3];
			}
		}
	}
}

- (void)didFinishDownloadForType:(DataDownloadType)type {
	[self saveData:_currentDataSamples type:type];
	_currentDataSamples = [NSMutableArray array];
	
	//start loading next data type
	DataDownloadType downloadType = DataDownloadTypeTemperature;
	switch (type) {
		case DataDownloadTypeTemperature:
			if (_deviceVersion == 13) {
				downloadType = DataDownloadTypeFinish;
				[TDSharedDevice sharedDevice].selectedDevice.lastDownload = [NSDate date];
				[(TempoDiscDevice*)[TDSharedDevice sharedDevice].selectedDevice setLogCount:_logCounter];
				if (_completion) {
					_completion(YES);
					_completion = nil;
					[_timerDataParseTimeout invalidate];
					_timerDataParseTimeout = nil;
				}
			}
			downloadType = DataDownloadTypeHumidity;
			break;
		case  DataDownloadTypeHumidity:
			if (_deviceVersion == 27) {
				downloadType = DataDownloadTypePressure;
			}
			else {
				downloadType = DataDownloadTypeDewPoint;
			}
			break;
		case DataDownloadTypeDewPoint:
		case DataDownloadTypePressure:
			downloadType = DataDownloadTypeFinish;
			[(TempoDiscDevice*)[TDSharedDevice sharedDevice].selectedDevice setLogCount:_logCounter];
			[TDSharedDevice sharedDevice].selectedDevice.lastDownload = [NSDate date];
			if ([TDSharedDevice sharedDevice].selectedDevice.version.integerValue == 27) {
				[self fillDewpointsDataForDevice:[TDSharedDevice sharedDevice].selectedDevice];
			}
			if (_completion) {
				_completion(YES);
				_completion = nil;
				[_timerDataParseTimeout invalidate];
				_timerDataParseTimeout = nil;
			}
			break;
		case DataDownloadTypeFirstMovement:
			//version 32 only
			downloadType = DataDownloadTypeSecondMovement;
			break;
		case DataDownloadTypeSecondMovement:
			//version 32 only
			downloadType = DataDownloadTypeFinish;
			[(TempoDiscDevice*)[TDSharedDevice sharedDevice].selectedDevice setLogCount:_logCounter];
			[TDSharedDevice sharedDevice].selectedDevice.lastDownload = [NSDate date];
			if ([TDSharedDevice sharedDevice].selectedDevice.version.integerValue == 27) {
				[self fillDewpointsDataForDevice:[TDSharedDevice sharedDevice].selectedDevice];
			}
			if (_completion) {
				_completion(YES);
				_completion = nil;
				[_timerDataParseTimeout invalidate];
				_timerDataParseTimeout = nil;
			}
			break;
		case DataDownloadTypeOpenClose:
			//version 52 only
			downloadType = DataDownloadTypeFinish;
			[(TempoDiscDevice*)[TDSharedDevice sharedDevice].selectedDevice setLogCount:_logCounter];
			[TDSharedDevice sharedDevice].selectedDevice.lastDownload = [NSDate date];
			if (_completion) {
				_completion(YES);
				_completion = nil;
				[_timerDataParseTimeout invalidate];
				_timerDataParseTimeout = nil;
			}
			break;
		case DataDownloadTypeLux:
			//version 62 only
			downloadType = DataDownloadTypeFinish;
			[(TempoDiscDevice*)[TDSharedDevice sharedDevice].selectedDevice setLogCount:_logCounter];
			[TDSharedDevice sharedDevice].selectedDevice.lastDownload = [NSDate date];
			if (_completion) {
				_completion(YES);
				_completion = nil;
				[_timerDataParseTimeout invalidate];
				_timerDataParseTimeout = nil;
			}
			break;
		case DataDownloadTypeFinish:
			downloadType = DataDownloadTypeTemperature;
			break;
	}
	
	_currentDownloadType = downloadType;
	
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
			break;
		case DataDownloadTypePressure:
			readingType = @"Pressure";
			break;
		case DataDownloadTypeFirstMovement:
			readingType = @"FirstMovement";
			break;
		case DataDownloadTypeSecondMovement:
			readingType = @"SecondMovement";
			break;
		case DataDownloadTypeOpenClose:
			readingType = @"OpenClose";
			break;
		case DataDownloadTypeLux:
			readingType = @"Light";
			break;
		case DataDownloadTypeFinish:
			break;
	}
	if (readingType) {
		NSDate *timestamp = _downloadStartTimestamp;
		for (ReadingType *type in [TDSharedDevice sharedDevice].selectedDevice.readingTypes) {
			if ([type.type isEqualToString:readingType]) {
				[[TDSharedDevice sharedDevice].selectedDevice removeReadingTypesObject:type];
				break;
			}
		}
        [NSThread sleepForTimeInterval: 1.0];
		[[TDSharedDevice sharedDevice].selectedDevice addData:data forReadingType:readingType startTimestamp:timestamp interval:[(TempoDiscDevice*)[TDSharedDevice sharedDevice].selectedDevice timerInterval].integerValue context:[(AppDelegate*)[UIApplication sharedApplication].delegate managedObjectContext]];
        [NSThread sleepForTimeInterval: 1.0];
	}
	
}

- (void)handleTimeout:(NSTimer*)timer {
	NSLog(@"Connect timeout reached");
	if (_completion) {
		_completion(NO);
	}
}

- (void)handleDisconnectNotification:(NSNotification*)note {
	NSLog(@"Device disconnected");
	if (_completion) {
		_completion(NO);
		_completion = nil;
		[_timerDataParseTimeout invalidate];
		_timerDataParseTimeout = nil;
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
	_deviceVersion = device.version.integerValue;
	if (_deviceVersion == 32) {
		_currentDownloadType = DataDownloadTypeFirstMovement;
	}
	else if (_deviceVersion == 52) {
		_currentDownloadType = DataDownloadTypeOpenClose;
	}
	else if (_deviceVersion == 62) {
		_currentDownloadType = DataDownloadTypeLux;
	}
	NSLog(@"Connecting to device...");
	__block NSTimer *timer = [NSTimer timerWithTimeInterval:kDeviceConnectTimeout target:self selector:@selector(handleTimeout:) userInfo:nil repeats:NO];
	[[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDisconnectNotification:) name:kLGPeripheralDidDisconnect object:nil];
	__weak typeof(self) weakself = self;
	[[LGCentralManager sharedInstance] scanForPeripheralsByInterval:kDeviceReConnectTimeout completion:^(NSArray *peripherals) {
		for (LGPeripheral *peripheral in peripherals) {
			if ([peripheral.UUIDString isEqualToString:[TDSharedDevice sharedDevice].selectedDevice.peripheral.UUIDString]) {
				[TDSharedDevice sharedDevice].selectedDevice.peripheral = peripheral;
				[[TDSharedDevice sharedDevice].selectedDevice.peripheral connectWithTimeout:kDeviceConnectTimeout completion:^(NSError *error) {
					[timer invalidate];
					timer = nil;
					weakself.didDisconnect = NO;
					if (!error) {
						NSLog(@"Connected to device");
						NSLog(@"Discovering device services...");
						[[TDSharedDevice sharedDevice].selectedDevice.peripheral discoverServicesWithCompletion:^(NSArray *services, NSError *error2) {
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
													[weakself writeData:kDataDownloadString toCharacteristic:weakself.writeCharacteristic];
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
				break;
			}
		}
	}];
}

- (void)writeData:(NSString *)data toDevice:(TDTempoDisc *)device withCompletion:(DataDownloadCompletion)completion {
	_currentDataSamples = [NSMutableArray array];
	_downloadStartTimestamp = [NSDate date];
	_deviceVersion = device.version.integerValue;
	_finish = completion;
	if (_deviceVersion == 32) {
		_currentDownloadType = DataDownloadTypeFirstMovement;
	}
	NSLog(@"Connecting to device...");
	__block NSTimer *timer = [NSTimer timerWithTimeInterval:kDeviceConnectTimeout target:self selector:@selector(handleTimeout:) userInfo:nil repeats:NO];
	[[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDisconnectNotification:) name:kLGPeripheralDidDisconnect object:nil];
	__weak typeof(self) weakself = self;
	[[LGCentralManager sharedInstance] scanForPeripheralsByInterval:kDeviceReConnectTimeout completion:^(NSArray *peripherals) {
		for (LGPeripheral *peripheral in peripherals) {
			if ([peripheral.UUIDString isEqualToString:device.peripheral.UUIDString]) {
				[peripheral connectWithTimeout:kDeviceConnectTimeout completion:^(NSError *error) {
					[timer invalidate];
					timer = nil;
					weakself.didDisconnect = NO;
					if (!error) {
						NSLog(@"Connected to device");
						NSLog(@"Discovering device services...");
						[peripheral discoverServicesWithCompletion:^(NSArray *services, NSError *error2) {
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
													_finish(NO);
												}
												if (!weakself.writeCharacteristic) {
													NSLog(@"Could not find RX characteristic");
													_finish(NO);
												}
												if (weakself.writeCharacteristic) {
													[weakself writeData:data toCharacteristic:weakself.writeCharacteristic];
													weakself.dataToSend = nil;
												}
											}
											else {
												NSLog(@"Error discovering device characteristics: %@", error3);
												_finish(NO);
											}
										}];
										break;
									}
								}
								if (!uartService) {
									NSLog(@"Failed to found UART service");
									_finish(NO);
								}
							}
							else {
								NSLog(@"Error discovering device services: %@", error2);
								_finish(NO);
							}
						}];
					}
					else {
						NSLog(@"Error connecting to device: %@", error);
						_finish(NO);
					}
				}];
				break;
			}
		}
	}];
}
@end
