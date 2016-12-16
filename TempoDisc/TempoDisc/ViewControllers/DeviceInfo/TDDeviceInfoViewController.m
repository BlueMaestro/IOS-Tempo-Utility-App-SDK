//
//  TDDeviceInfoViewController.m
//  TempoDisc
//
//  Created by Nikola Misic on 2/28/16.
//  Copyright © 2016 BlueMaestro. All rights reserved.
//

#import "TDDeviceInfoViewController.h"
#import <LGBluetooth/LGBluetooth.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "AppDelegate.h"
#import "DeviceInfoTableViewController.h"
#import "TempoDiscDevice+CoreDataProperties.h"
//#import "TDUARTDownloader.h"
#import "TDUARTAllDataDownloader.h"

#define kDeviceConnectTimeout 10.0

//independent tasks
#define TEMPO_CUSTOM @"20652000-02F3-4F75-848F-323AC2A6AF8A"
#define TEMPO_BATTERY_SERVICE @"180F"
#define TEMPO_VERSION_SERVICE @"180A"
#define TEMPO_BATTERY @"2A19"
#define TEMPO_VERSION @"2A28"

#define TEMPO_TS_TEMP @"20653010-02F3-4F75-848F-323AC2A6AF8A"
#define TEMPO_TS_HUMIDITY @"20653020-02F3-4F75-848F-323AC2A6AF8A"
#define TEMPO_TS_PRESSURE @"20653030-02F3-4F75-848F-323AC2A6AF8A"

#define TEMPO_WC_TEMP @"20653011-02F3-4F75-848F-323AC2A6AF8A"
#define TEMPO_WC_HUMIDITY @"20653021-02F3-4F75-848F-323AC2A6AF8A"
#define TEMPO_WC_PRESSURE @"20653031-02F3-4F75-848F-323AC2A6AF8A"

#define TEMPO_DATA_TEMP @"20653012-02F3-4F75-848F-323AC2A6AF8A"
#define TEMPO_DATA_HUMIDITY @"20653022-02F3-4F75-848F-323AC2A6AF8A"
#define TEMPO_DATA_PRESSURE @"20653032-02F3-4F75-848F-323AC2A6AF8A"

#define TEMPO_NAME @"20652010-02F3-4F75-848F-323AC2A6AF8A"
#define TEMPO_FIND @"20652011-02F3-4F75-848F-323AC2A6AF8A"
#define TEMPO_iBEACON @"20652012-02F3-4F75-848F-323AC2A6AF8A"

#define TEMP_SAMPLES_IN_DATA 3
#define HUMIDTY_SAMPLES_IN_DATA 12

#define INVALID_TEMP_VALUE -3276.8f
#define INVALID_HUMIDITY_VALUE -1

@interface TDDeviceInfoViewController ()

@property (nonatomic, strong) NSDateFormatter *formatterLastDownload;

@property (nonatomic, strong) MBProgressHUD *hudDownloadData;

@property (nonatomic, strong) LGService *dataDownloadService;
@property (nonatomic, strong) LGService *batteryService;
@property (nonatomic, strong) LGService *versionService;

@property (nonatomic, strong) LGCharacteristic* temperatureWindow;
@property (nonatomic, strong) LGCharacteristic *temperatureControl;
@property (nonatomic, strong) LGCharacteristic *temperatureTimeSync;

@property (nonatomic, strong) LGCharacteristic* humidityWindow;
@property (nonatomic, strong) LGCharacteristic *humidityControl;
@property (nonatomic, strong) LGCharacteristic *humidityTimeSync;

@property (nonatomic, strong) DeviceInfoTableViewController *controllerTable;

@property (nonatomic, strong) TDUARTDownloader *uartDownloader;
@property (nonatomic, strong) TDUARTAllDataDownloader *uartAllDataDownloader;

@end

@implementation TDDeviceInfoViewController

#pragma mark - Data Parse

- (int)getIntLsb:(char)lsb msb:(char)msb {
	return (((int) lsb) & 0xFF) | (((int) msb) << 8);
}

- (int)parseTempData:(int)numSamples characteristic:(CBCharacteristic*)dataChar collection:(NSMutableArray*)collection {
	char *data = (char *)[dataChar.value bytes];
	
	for (int i = 0;i< TEMP_SAMPLES_IN_DATA && numSamples > 0 ; i++)
	{
		float min = [self getIntLsb:data[0 + i*6] msb:data[3 + i*6]] / 10.0f;
		float avg = [self getIntLsb:data[2 + i*6] msb:data[3 + i*6]] / 10.0f;
		float max = [self getIntLsb:data[4 + i*6] msb:data[5 + i*6]] / 10.0f;
		
		NSLog(@"Min %f  Avg %f Max %f",min,avg,max);
		if (min == INVALID_TEMP_VALUE) {
			NSLog(@"Invalid Temperature value. Aborting...");
			numSamples = 0;
		} else {
			
			[collection addObject:[[NSArray alloc] initWithObjects:[NSNumber numberWithFloat:min],[NSNumber numberWithFloat:avg], [NSNumber numberWithFloat:max], nil]];
			
			numSamples--;
		}
	}
	
	return numSamples;
}

- (int)parseHumidityValue:(int)numSamples characeristic:(CBCharacteristic*)dataChar collection:(NSMutableArray*)collection {
	char *data = (char *)[dataChar.value bytes];
	
	for (int i = 0;i< HUMIDTY_SAMPLES_IN_DATA && numSamples > 0 ; i++)
	{
		int value = data[i];
		
		NSLog(@"Humidity value: %d",value);
		if (value == INVALID_HUMIDITY_VALUE) {
			NSLog(@"Invalid Humidity value. Aborting...");
			numSamples = 0;
		} else {
			
			[collection addObject:[[NSArray alloc] initWithObjects:[NSNumber numberWithInt:value], nil]];
			
			numSamples--;
		}
	}
	
	return numSamples;
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	[self setupView];
	[self fillData];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	//refresh device
	[self refreshCurrentDevice];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
	if ([segue.destinationViewController isKindOfClass:[DeviceInfoTableViewController class]]) {
		_controllerTable = segue.destinationViewController;
	}
}


#pragma mark - Private methods

- (void)setupView {
	[super setupView];
	_formatterLastDownload = [[NSDateFormatter alloc] init];
	_formatterLastDownload.dateFormat = @"HH:mm EEEE d";
	
	_buttonDownload.layer.borderColor = [UIColor blackColor].CGColor;
	_buttonDownload.layer.borderWidth = 1.0;
	_buttonDownload.layer.cornerRadius = 12;
	_buttonDownload.clipsToBounds = YES;
	
	_buttonUART.layer.borderColor = [UIColor blackColor].CGColor;
	_buttonUART.layer.borderWidth = 1.0;
	_buttonUART.layer.cornerRadius = 12;
	_buttonUART.clipsToBounds = YES;

}

- (void)fillData {
	_labelTemperatureValue.text = [NSString stringWithFormat:@"%.1f˚%@", [TDHelper temperature:[TDDefaultDevice sharedDevice].selectedDevice.currentTemperature forDevice:[TDDefaultDevice sharedDevice].selectedDevice].floatValue, [TDDefaultDevice sharedDevice].selectedDevice.isFahrenheit.boolValue ? @"F" : @"C"];
	_labelHumidityValue.text = [NSString stringWithFormat:@"%ld%%", (long)[TDDefaultDevice sharedDevice].selectedDevice.currentHumidity.integerValue];
	if ([TDDefaultDevice sharedDevice].selectedDevice.lastDownload) {
		_labelLastDownloadTimestamp.text = [_formatterLastDownload stringFromDate:[TDDefaultDevice sharedDevice].selectedDevice.lastDownload];
	}
	else {
		_labelLastDownloadTimestamp.text = NSLocalizedString(@"Not yet downloaded", nil);
	}
	_labelRSSI.text = [NSString stringWithFormat:@"%lddbm", [TDDefaultDevice sharedDevice].selectedDevice.peripheral.RSSI];
	_labelUUID.text = [TDDefaultDevice sharedDevice].selectedDevice.peripheral.UUIDString;
	_labelVersion.text = [TDDefaultDevice sharedDevice].selectedDevice.version;
}

#pragma mark - Sync

- (void)downloadDataFromPeripheral:(LGPeripheral*)peripheral {
	_hudDownloadData.labelText = NSLocalizedString(@"Searching for device...", nil);
	[peripheral connectWithTimeout:kDeviceConnectTimeout completion:^(NSError *connectError) {
		if (!connectError) {
			_hudDownloadData.labelText = NSLocalizedString(@"Discovering services", nil);
			//discover all services
			[peripheral discoverServicesWithCompletion:^(NSArray *services, NSError *discoverError) {
				if (!discoverError) {
					_dataDownloadService = nil;
					_batteryService = nil;
					_versionService = nil;
					for (LGService *service in services) {
						if ([[service.UUIDString uppercaseString] isEqualToString:TEMPO_CUSTOM]) {
							_dataDownloadService = service;
						}
						else if ([[service.UUIDString uppercaseString] isEqualToString:TEMPO_BATTERY_SERVICE]) {
							_batteryService = service;
						}
						else if ([[service.UUIDString uppercaseString] isEqualToString:TEMPO_VERSION_SERVICE]) {
							_versionService = service;
						}
					}
					/**
					 *	Start download process in order
					 *	1. Battery
					 *	2. Version
					 *	3. Data
					 **/
					if (_batteryService) {
						[self downloadBatteryDataFromService:_batteryService];
					}
					else {
						[self abortConnectionWithErrorMessage:NSLocalizedString(@"Could not find service with battery download UUID", nil)];
					}
				}
				else {
					[self abortConnectionWithErrorMessage:[NSString stringWithFormat:NSLocalizedString(@"Error discovering services for peripheral: %@", nil), discoverError.localizedDescription]];
				}
			}];
		}
		else {
			[self abortConnectionWithErrorMessage:[NSString stringWithFormat:NSLocalizedString(@"Error connecting to peripheral: %@", nil), connectError.localizedDescription]];
		}
	}];
}

- (void)downloadBatteryDataFromService:(LGService*)service {
	_hudDownloadData.labelText = NSLocalizedString(@"Connecting...", nil);
	[service discoverCharacteristicsWithCompletion:^(NSArray *characteristics, NSError *error) {
		for (LGCharacteristic *characteristic in characteristics) {
			if ([[characteristic.UUIDString uppercaseString] isEqualToString:TEMPO_BATTERY]) {
				[characteristic readValueWithBlock:^(NSData *data, NSError *error) {
					if (data) {
						//got the data, parse it
						uint8_t value;
						[data getBytes:&value length:1];
						NSNumber *valueBattery = [NSNumber numberWithUnsignedShort:value];
						//set battery level
						[TDDefaultDevice sharedDevice].selectedDevice.battery = [NSDecimalNumber decimalNumberWithDecimal:valueBattery.decimalValue];
						NSLog(@"Read battery data: %@, value: %@", data, valueBattery.stringValue);
						
						//finished downloading battery data. Continue.
						if (_versionService) {
							[self downloadVersionDataFromService:_versionService];
						}
						else {
							[self abortConnectionWithErrorMessage:[NSString stringWithFormat:NSLocalizedString(@"Could not find battery service", nil), error]];
						}
					}
					else {
						[self abortConnectionWithErrorMessage:[NSString stringWithFormat:NSLocalizedString(@"Error reading battery data", nil), error]];
					}
					
				}];
				return;
			}
		}
		[self abortConnectionWithErrorMessage:NSLocalizedString(@"Could not find battery characteristic to read from", nil)];
	}];
}

- (void)downloadVersionDataFromService:(LGService*)service {
	_hudDownloadData.labelText = NSLocalizedString(@"Downloading version data...", nil);
	[service discoverCharacteristicsWithCompletion:^(NSArray *characteristics, NSError *error) {
		for (LGCharacteristic *characteristic in characteristics) {
			if ([[characteristic.UUIDString uppercaseString] isEqualToString:TEMPO_VERSION]) {
				[characteristic readValueWithBlock:^(NSData *data, NSError *error) {
					if (data) {
						//parse data
						NSString *version = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
						NSLog(@"Read version data: %@", version);
						[TDDefaultDevice sharedDevice].selectedDevice.version = version;
						
						//finished version download. Continue
						if (_dataDownloadService) {
							[self downloadDataFromService:_dataDownloadService];
						}
						else {
							[self abortConnectionWithErrorMessage:[NSString stringWithFormat:NSLocalizedString(@"Could not find version service", nil), error]];
						}
					}
					else {
						[self abortConnectionWithErrorMessage:[NSString stringWithFormat:NSLocalizedString(@"Error reading version data", nil), error]];
					}
					
				}];
				return;
			}
		}
		[self abortConnectionWithErrorMessage:NSLocalizedString(@"Could not find version characteristic to read from", nil)];
	}];
}

- (void)downloadDataFromService:(LGService*)service {
	_hudDownloadData.labelText = NSLocalizedString(@"Discovering data service...", nil);
	[service discoverCharacteristicsWithCompletion:^(NSArray *characteristics, NSError *discoverCharacteristicsError) {
		if (!discoverCharacteristicsError) {
			_temperatureTimeSync = nil;
			_temperatureControl = nil;
			_temperatureWindow = nil;
			_humidityControl = nil;
			_humidityTimeSync = nil;
			_humidityWindow = nil;
			for (LGCharacteristic *characteristic in characteristics) {
				//get time characteristics
				if ([[characteristic.UUIDString uppercaseString] isEqualToString:TEMPO_TS_TEMP]) {
					_temperatureTimeSync = characteristic;
				}
				else if ([[characteristic.UUIDString uppercaseString] isEqualToString:TEMPO_WC_TEMP]) {
					_temperatureControl = characteristic;
				}
				else if ([[characteristic.UUIDString uppercaseString] isEqualToString:TEMPO_DATA_TEMP]) {
					_temperatureWindow = characteristic;
				}
				else if ([[characteristic.UUIDString uppercaseString] isEqualToString:TEMPO_TS_HUMIDITY]) {
					_humidityTimeSync = characteristic;
				}
				else if ([[characteristic.UUIDString uppercaseString] isEqualToString:TEMPO_WC_HUMIDITY]) {
					_humidityControl = characteristic;
				}
				else if ([[characteristic.UUIDString uppercaseString] isEqualToString:TEMPO_DATA_HUMIDITY]) {
					_humidityWindow = characteristic;
				}
			}
			if (_temperatureWindow && _temperatureControl && _temperatureControl) {
				/**
				 *	All required services have been found
				 *	Start downloading data
				 **/
				[self startDataDownloadWithTimeSyncCharacteristic:_temperatureTimeSync windowCharacteristic:_temperatureControl dataCharacteristic:_temperatureWindow type:TempoReadingTypeTemperature];
			}
			else {
				[self abortConnectionWithErrorMessage:NSLocalizedString(@"Could not find all characteristics for data download", nil)];
			}
		}
		else {
			[self abortConnectionWithErrorMessage:[NSString stringWithFormat:@"Error discovering charachteristics for service: %@", discoverCharacteristicsError.localizedDescription]];
		}
	}];
}

- (void)startDataDownloadWithTimeSyncCharacteristic:(LGCharacteristic*)time windowCharacteristic:(LGCharacteristic*)windowControl dataCharacteristic:(LGCharacteristic*)window type:(TempoReadingType)type {
	_hudDownloadData.labelText = NSLocalizedString(@"Downloading data", nil);
	[time readValueWithBlock:^(NSData *readData, NSError *error) {
		char *data = (char *)[readData bytes];
		if (data != nil) {
			//ignoring timesync for now. Assume 1h.
			/*int count = [self getIntLsb:data[0] msb:data[1]];
			int countRoll = [self getIntLsb:data[2] msb:data[3]];*/
			int totalSamples = [self getIntLsb:data[4] msb:data[5]];
			/*int calibration = [self getIntLsb:data[6] msb:data[7]];
			
			NSDate *lastSample =[NSDate dateWithTimeIntervalSinceNow:-count];*/
			
			__block int numSamples;
			int sampleCount = 1;                    //skip the first sample
			int totalNeeded = totalSamples;
			
			//read window control
			[windowControl readValueWithBlock:^(NSData *readData, NSError *error) {
				char *data = (char *)[readData bytes];
				int w = [self getIntLsb:data[0] msb:data[1]];
				NSLog(@"Current window %d",w);
				
				//Someone else reading
				if (w != 0) {
					NSLog(@"Error, someone else is reading wc characteristic: %@", windowControl);
					numSamples = 0;
				} else {
					//dummy read
					[time readValueWithBlock:^(NSData *data, NSError *error) {
						[self readDataFromCharacteristic:window withControl:windowControl totalSamples:totalNeeded windowNumber:sampleCount collection:[NSMutableArray array] type:type];
					}];
					
					//Wait for the read to complete
				}
			}];
			
			
		}
	}];
}

- (void)readDataFromCharacteristic:(LGCharacteristic*)window withControl:(LGCharacteristic*)windowControl totalSamples:(int)total windowNumber:(int)page collection:(NSMutableArray*)collection type:(TempoReadingType)type {
	__block int newTotal = total;
	NSLog(@"reading sample page %ld/%ld", (long)page, (long)total);
	if (total == 0) {
		[self abortConnectionWithErrorMessage:nil];
	}
	else {
		unsigned char value[2];
		value[0] = page & 0xFF;
		value[1] = (page >> 8) &0xFF;
		//write next window and read data
		[windowControl writeValue:[NSData dataWithBytes:&value length:sizeof(value)] completion:^(NSError *error) {
			[window readValueWithBlock:^(NSData *readData, NSError *error) {
				if (type == TempoReadingTypeTemperature) {
					newTotal = [self parseTempData:newTotal characteristic:window.cbCharacteristic collection:collection];
				}
				else if (type == TempoReadingTypeHumidity) {
					newTotal = [self parseHumidityValue:newTotal characeristic:window.cbCharacteristic collection:collection];
				}
				else {
					//unsupported data type
					newTotal = 0;
				}
				if (newTotal > 0) {
					//continue reading
					[self readDataFromCharacteristic:window withControl:windowControl totalSamples:newTotal windowNumber:page+3 collection:collection type:type];
				}
				else {
					//storage count hit or invalid value found. Abort reading.
					[self finishedDataReadForDataType:type collection:collection];
				}
			}];
		}];
	}
}

- (void)insertData:(NSArray*)collection forReadingType:(TempoReadingType)type {
	NSString *readingType;
	switch (type) {
  case TempoReadingTypeTemperature:
			readingType = @"Temperature";
			break;
		case TempoReadingTypeHumidity:
			readingType = @"Humidity";
  default:
			break;
	}
	if (readingType) {
		[[TDDefaultDevice sharedDevice].selectedDevice addData:collection forReadingType:readingType context:[(AppDelegate*)[UIApplication sharedApplication].delegate managedObjectContext]];
	}
}

- (void)finishedDataReadForDataType:(TempoReadingType)type collection:(NSMutableArray*)collection {
	[_controllerTable.tableView reloadData];
	if (collection.count > 0) {
		[self insertData:collection forReadingType:type];
	}
	switch (type) {
  case TempoReadingTypeTemperature:
			[self startDataDownloadWithTimeSyncCharacteristic:_humidityTimeSync windowCharacteristic:_humidityControl dataCharacteristic:_humidityWindow type:TempoReadingTypeHumidity];
			break;
			
  default:
			//finished with humidity read, no more data. Finish sync.
			if (collection.count > 0) {
				[TDDefaultDevice sharedDevice].selectedDevice.lastDownload = [NSDate date];
				[self fillData];
			}
			[self abortConnectionWithErrorMessage:[NSString stringWithFormat:@"Downloaded %ld samples", (long)collection.count]];
			break;
	}
	
}

/**
 *	Main method for stoping device sync
 *	@param message Message to display after download stop.
 */
- (void)abortConnectionWithErrorMessage:(NSString*)message  {
	[[TDDefaultDevice sharedDevice].selectedDevice.peripheral disconnectWithCompletion:nil];
	[MBProgressHUD hideAllHUDsForView:self.view animated:NO];
	UIAlertController *controller = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Download finished", nil) message:message preferredStyle:UIAlertControllerStyleAlert];
	[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleCancel handler:nil]];
	[self presentViewController:controller animated:YES completion:nil];
	[TDDefaultDevice sharedDevice].selectedDevice.peripheral = nil;
}

#pragma mark - Actions

- (IBAction)buttonDownloadClicked:(UIButton *)sender {
	if ([[TDDefaultDevice sharedDevice].selectedDevice isKindOfClass:[TempoDiscDevice class]]) {
		UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Download data", nil) message:NSLocalizedString(@"", nil) preferredStyle:UIAlertControllerStyleAlert];
		
		__weak typeof(self) weakself = self;
        /*
		[alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Download All", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
			if (!weakself.uartAllDataDownloader) {
				weakself.uartAllDataDownloader = [[TDUARTAllDataDownloader alloc] init];
			}
			
			weakself.hudDownloadData = [MBProgressHUD showHUDAddedTo:weakself.view animated:YES];
			weakself.hudDownloadData.labelText = NSLocalizedString(@"Downloading data...", nil);
			[weakself.uartAllDataDownloader downloadDataForDevice:(TempoDiscDevice*)[TDDefaultDevice sharedDevice].selectedDevice withCompletion:^(BOOL succcess) {
				[weakself.hudDownloadData hide:YES];
				weakself.uartAllDataDownloader = nil;
				if (!succcess) {
					UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", nil) message:NSLocalizedString(@"Cannot download at this time. Try scanning for the device again in the Device List screen", nil) preferredStyle:UIAlertControllerStyleAlert];
					[alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Dismiss", nil) style:UIAlertActionStyleCancel handler:nil]];
					[weakself presentViewController:alert animated:YES completion:nil];
				}
				[weakself refreshCurrentDevice];
			}];
		}]];*/
		
		[alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Download New", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
			if (!weakself.uartDownloader) {
				weakself.uartDownloader = [[TDUARTDownloader alloc] init];
			}
			
			weakself.hudDownloadData = [MBProgressHUD showHUDAddedTo:weakself.view animated:YES];
			weakself.hudDownloadData.labelText = NSLocalizedString(@"Downloading data...", nil);
			[weakself.uartDownloader downloadDataForDevice:(TempoDiscDevice*)[TDDefaultDevice sharedDevice].selectedDevice withCompletion:^(BOOL succcess) {
				[weakself.hudDownloadData hide:YES];
				weakself.uartDownloader = nil;
				if (!succcess) {
					UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", nil) message:NSLocalizedString(@"Unable to download. Please try again", nil) preferredStyle:UIAlertControllerStyleAlert];
					[alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Dismiss", nil) style:UIAlertActionStyleCancel handler:nil]];
					[weakself presentViewController:alert animated:YES completion:nil];
				}
				[weakself refreshCurrentDevice];
			}];
		}]];
		
		[alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil]];
		
		[self presentViewController:alert animated:YES completion:nil];
	}
	else {
		_hudDownloadData = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
		_hudDownloadData.labelText = NSLocalizedString(@"Searching for device...", nil);
		LGPeripheral *peripheral = [TDDefaultDevice sharedDevice].selectedDevice.peripheral;
		if (peripheral) {
			//peripheral is in range
			[self downloadDataFromPeripheral:peripheral];
		}
		else {
			//peripheral is not in range search for it before download
			[[LGCentralManager sharedInstance] scanForPeripheralsByInterval:2 completion:^(NSArray *peripherals) {
				LGPeripheral *targetPeripheral;
				for (LGPeripheral *peripheral in peripherals) {
					if ([peripheral.cbPeripheral.identifier.UUIDString isEqualToString:[TDDefaultDevice sharedDevice].selectedDevice.uuid]) {
						targetPeripheral = peripheral;
						break;
					}
				}
				if (targetPeripheral) {
					[TDDefaultDevice sharedDevice].selectedDevice.peripheral = targetPeripheral;
					[self downloadDataFromPeripheral:targetPeripheral];
				}
				else {
					[self abortConnectionWithErrorMessage:NSLocalizedString(@"Could not find device peripheral", nil)];
				}
			}];
		}
	}
}

@end
