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

#define kDeviceConnectTimeout			10.0
#define kDeviceReConnectTimeout			1.0

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
@property (nonatomic, copy) DataProgressUpdate update;

@property (nonatomic, strong) NSNumber *logCounter;

@property (nonatomic, assign) NSInteger totalCurrentSample;

@property (nonatomic, strong) NSDate *startingTimeStamp;

@end

@implementation TDUARTDownloader

#pragma mark - Private methods

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:kLGPeripheralDidDisconnect object:nil];
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
		}
		else {
			NSLog(@"Error writing data to characteristic: %@", error);
		}
	}];
}

- (void)parseData:(NSData*)data {
    char * d = (char *)data.bytes;
	NSLog(@"data received: %@", data);
	if (d[14] == kDataTerminationHeaderValue) {
		NSLog(@"Header data received: %@", data);
        NSInteger sendLogPointer = [self getIntLsb:d[1] msb:d[0]];
        NSInteger sendRecordsNeeded = [self getIntLsb:d[3] msb:d[2]];
        NSUInteger sendGlobalLogCount = [self getIntLsb:d[5] msb:d[4]];
        NSInteger sendRecordSize = [self getIntLsb:d[7] msb:d[6]];
        NSInteger mode = d[8];
        NSInteger alarmFlag = d[9];
        NSInteger alarm1Value = [self getIntLsb:d[11] msb:d[10]];
        NSInteger alarm2Value = [self getIntLsb:d[13] msb:d[14]];
        NSLog(@"---------------------------------------");
        NSLog(@"Header data parsed");
        NSLog(@"send_log_pointer : %ld", (long)sendLogPointer);
        NSLog(@"send_records_needed: %ld", (long)sendRecordsNeeded);
        NSLog(@"send_global_log_count: %lu", (unsigned long)sendGlobalLogCount);
        NSLog(@"send_record_size: %ld", (long)sendRecordSize);
        NSLog(@"mode: %ld", (long)mode);
        NSLog(@"alarm_flag_for_header: %ld", (long)alarmFlag);
        NSLog(@"alarm_1_value: %ld", (long)alarm1Value);
        NSLog(@"alarm_2_value: %ld", (long)alarm2Value);
        //header data, parse next point and dont impor
        NSUInteger nextCounter = [self getIntLsb:d[5] msb:d[4]];
        _logCounter = @(nextCounter);
		_totalCurrentSample = sendGlobalLogCount;
        [self setNewTimeStamp:sendRecordsNeeded];
		
		switch (_currentDownloadType) {
			case DataDownloadTypeTemperature:
				[self notifyUpdateForProgress:0.0];
				break;
			case DataDownloadTypeHumidity:
				[self notifyUpdateForProgress:1/3.0];
				break;
			case DataDownloadTypeDewPoint:
				[self notifyUpdateForProgress:2/3.0];
				
			default:
				break;
		}
        return;
    }
	
	NSInteger length = data.length;
	float baseProgress = 0.0;
	for (NSInteger i=0; i<length; i+=2) {
		if (d[i] == kDataTerminationValue) {
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
					break;
				case DataDownloadTypeHumidity:
					baseProgress = 1/3.0;
					type = @"H";
					break;
				case DataDownloadTypeDewPoint:
					type = @"D";
					baseProgress = 2/3.0;
					break;
				default:
					break;
			}
			NSLog(@"sample raw value: %@. Record number: %lu. Type: %@", [data subdataWithRange:NSMakeRange(i, 2)], (unsigned long)_currentDataSamples.count, type);
			NSInteger value = [self getIntLsb:d[i+1] msb:d[i]];
			NSLog(@"Sample parsed value: %ld", (long)value);
			[_currentDataSamples addObject:@[@(value / 10.f)]];
			[self notifyUpdateForProgress:baseProgress+((float)_currentDataSamples.count / (float)_totalCurrentSample)*0.3];
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
            //Download all data, not just missing data
            stringToWrite = [NSString stringWithFormat:@"%@0", kDataStringHumidity];
			//stringToWrite = [NSString stringWithFormat:@"%@%@", kDataStringHumidity, [(TempoDiscDevice*)[TDSharedDevice sharedDevice].selectedDevice logCount]];
			break;
		case  DataDownloadTypeHumidity:
			downloadType = DataDownloadTypeDewPoint;
            //Download all data, not just missing data
            stringToWrite = [NSString stringWithFormat:@"%@0", kDataStringDewPoint];
			//stringToWrite = [NSString stringWithFormat:@"%@%@", kDataStringDewPoint, [(TempoDiscDevice*)[TDSharedDevice sharedDevice].selectedDevice logCount]];
			break;
		case DataDownloadTypeDewPoint:
			downloadType = DataDownloadTypeFinish;
			stringToWrite = kDataStringTransmitEnd;
			[(TempoDiscDevice*)[TDSharedDevice sharedDevice].selectedDevice setLogCount:_logCounter];
			[TDSharedDevice sharedDevice].selectedDevice.lastDownload = [NSDate date];
			
			_update = nil;
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

        NSLog(@"Deleting old data");
        [[TDSharedDevice sharedDevice].selectedDevice deleteOldData:readingType context:[(AppDelegate*)[UIApplication sharedApplication].delegate managedObjectContext]];
        [NSThread sleepForTimeInterval: 1.0];
        
        NSLog(@"Writing new data");
		[[TDSharedDevice sharedDevice].selectedDevice addData:data forReadingType:readingType startTimestamp:_startingTimeStamp interval:[(TempoDiscDevice*)[TDSharedDevice sharedDevice].selectedDevice timerInterval].integerValue context:[(AppDelegate*)[UIApplication sharedApplication].delegate managedObjectContext]];
        [NSThread sleepForTimeInterval: 1.0];
        
	}
	
}

- (void)handleTimeout:(NSTimer*)timer {
	NSLog(@"Connect timeout reached");
	if (_completion) {
		_completion(NO);
		_completion = nil;
	}
}

- (void)handleDisconnectNotification:(NSNotification*)note {
	NSLog(@"Device disconnected");
	if (_completion) {
		_completion(NO);
		_completion = nil;
	}
}

- (void)setNewTimeStamp:(NSInteger)sendRecordsNeeded {
    NSInteger timeInterval = [[(TempoDiscDevice*)[TDSharedDevice sharedDevice].selectedDevice timerInterval] integerValue];
    NSDate *dateNow = [NSDate date];
    
    //Calculate start date
    NSTimeInterval totalSeconds = timeInterval * sendRecordsNeeded;
    _startingTimeStamp = [dateNow dateByAddingTimeInterval:-totalSeconds];
    NSLog(@"Records needed is %i, date now is %@, time interval is %i and starting date for logging is %@", (int)sendRecordsNeeded, dateNow, (int)timeInterval, _startingTimeStamp);
    
}

- (void)notifyUpdateForProgress:(float)progress {
	if (_update) {
		_update(progress);
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

- (void)downloadDataForDevice:(TempoDiscDevice *)device withUpdate:(DataProgressUpdate)update withCompletion:(DataDownloadCompletion)completion {
	_update = update;
	[self downloadDataForDevice:device withCompletion:completion];
}

- (void)downloadDataForDevice:(TempoDiscDevice *)device withCompletion:(void (^)(BOOL))completion {
	_currentDataSamples = [NSMutableArray array];
	_downloadStartTimestamp = [NSDate date];
	_completion = completion;
	NSLog(@"Connecting to device...");
	__block NSTimer *timer = [NSTimer timerWithTimeInterval:kDeviceConnectTimeout target:self selector:@selector(handleTimeout:) userInfo:nil repeats:NO];
	[[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
//	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDisconnectNotification:) name:kLGPeripheralDidDisconnect object:nil];
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
                                                    [weakself writeData:[NSString stringWithFormat:@"%@0", kDataStringTemperature] toCharacteristic:weakself.writeCharacteristic];
                                                    
													/*[weakself writeData:[NSString stringWithFormat:@"%@%@", kDataStringTemperature, [(TempoDiscDevice*)[TDSharedDevice sharedDevice].selectedDevice logCount]] toCharacteristic:weakself.writeCharacteristic];*/
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

@end
