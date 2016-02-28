//
//  TDDeviceInfoViewController.m
//  TempoDisc
//
//  Created by Nikola Misic on 2/28/16.
//  Copyright © 2016 BlueMaestro. All rights reserved.
//

#import "TDDeviceInfoViewController.h"
#import <LGBluetooth/LGBluetooth.h>
#import "AppDelegate.h"

#define kDeviceConnectTimeout 30.0

//independent tasks
#define TEMPO_CUSTOM @"20652000-02F3-4F75-848F-323AC2A6AF8A"

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

#define INVALID_TEMP_VALUE -3276.8f

@interface TDDeviceInfoViewController ()

@property (nonatomic, strong) NSDateFormatter *formatterLastDownload;

@end

@implementation TDDeviceInfoViewController

- (int)getIntLsb:(char)lsb msb:(char)msb {
	return (((int) lsb) & 0xFF) | (((int) msb) << 8);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	[self setupView];
	[self fillData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - Private methods

- (void)setupView {
	_formatterLastDownload = [[NSDateFormatter alloc] init];
	_formatterLastDownload.dateFormat = @"hh:mm EEEE d";
	
	_buttonDownload.layer.borderColor = [UIColor blackColor].CGColor;
	_buttonDownload.layer.borderWidth = 1.0;
	_buttonDownload.layer.cornerRadius = 12;
	_buttonDownload.clipsToBounds = YES;
}

- (void)fillData {
	_labelDeviceName.text = [TDDefaultDevice sharedDevice].selectedDevice.name;
	_labelTemperatureValue.text = [NSString stringWithFormat:@"%.1f", [TDDefaultDevice sharedDevice].selectedDevice.currentTemperature.floatValue];
	_labelHumidityValue.text = [NSString stringWithFormat:@"%ld%%", (long)[TDDefaultDevice sharedDevice].selectedDevice.currentHumidity.integerValue];
	if ([TDDefaultDevice sharedDevice].selectedDevice.lastDownload) {
		_labelLastDownloadTimestamp.text = [_formatterLastDownload stringFromDate:[TDDefaultDevice sharedDevice].selectedDevice.lastDownload];
	}
	else {
		_labelLastDownloadTimestamp.text = NSLocalizedString(@"Not yet downloaded", nil);
	}
}

#pragma mark - Sync

- (void)startDataDownloadWithTimeSyncCharacteristic:(LGCharacteristic*)time windowCharacteristic:(LGCharacteristic*)windowControl dataCharacteristic:(LGCharacteristic*)window {
	[time readValueWithBlock:^(NSData *readData, NSError *error) {
		char *data = (char *)[readData bytes];
		if (data != nil) {
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
						[self readDataFromCharacteristic:window withControl:windowControl totalSamples:totalNeeded windowNumber:sampleCount collection:[NSMutableArray array]];
					}];
					
					//Wait for the read to complete
				}
			}];
			
			
		}
	}];
}

- (void)readDataFromCharacteristic:(LGCharacteristic*)window withControl:(LGCharacteristic*)windowControl totalSamples:(int)total windowNumber:(int)page collection:(NSMutableArray*)collection {
	__block int newTotal = total;
	NSLog(@"reading sample page %ld/%ld", (long)page, (long)total);
	if (total == 0) {
		[self abortConnectionWithErrorMessage:nil];
	}
	else {
		unsigned char value[2];
		value[0] = page & 0xFF;
		value[1] = (page >> 8) &0xFF;
		[windowControl writeValue:[NSData dataWithBytes:&value length:sizeof(value)] completion:^(NSError *error) {
			[window readValueWithBlock:^(NSData *readData, NSError *error) {
				char *data = (char *)[readData bytes];
    
				for (int i = 0; i< 3 && total > 0 ; i++)
				{
					float min = [self getIntLsb:data[0 + i*6] msb:data[1 + i*6]] / 10.0f;
					float avg = [self getIntLsb:data[2 + i*6] msb:data[3 + i*6]] / 10.0f;
					float max = [self getIntLsb:data[4 + i*6] msb:data[5 + i*6]] / 10.0f;
					
					NSLog(@"Min %f  Avg %f Max %f",min,avg,max);
					if (min == INVALID_TEMP_VALUE) {
						NSLog(@"Invalid Temperature value. Aborting...");
						newTotal = 0;
					} else {
						
						[collection addObject:[[NSArray alloc] initWithObjects:[NSNumber numberWithFloat:min],[NSNumber numberWithFloat:avg], [NSNumber numberWithFloat:max], nil]];
						
						newTotal--;
					}
				}
				if (newTotal > 0) {
					[self readDataFromCharacteristic:window withControl:windowControl totalSamples:newTotal windowNumber:page+3 collection:collection];
				}
				else {
					if (collection.count > 0) {
						[[TDDefaultDevice sharedDevice].selectedDevice addData:collection forReadingType:@"Temperature" context:[(AppDelegate*)[UIApplication sharedApplication].delegate managedObjectContext]];
						[TDDefaultDevice sharedDevice].selectedDevice.lastDownload = [NSDate date];
						[self fillData];
					}
					[self abortConnectionWithErrorMessage:nil];
				}
			}];
		}];
	}
}

- (void)abortConnectionWithErrorMessage:(NSString*)message {
	[[TDDefaultDevice sharedDevice].selectedDevice.peripheral disconnectWithCompletion:nil];
	[MBProgressHUD hideAllHUDsForView:self.view animated:NO];
}

#pragma mark - Actions

- (IBAction)buttonDownloadClicked:(UIButton *)sender {
	[MBProgressHUD showHUDAddedTo:self.view animated:YES];
	LGPeripheral *peripheral = [TDDefaultDevice sharedDevice].selectedDevice.peripheral;
	if (peripheral) {
		[peripheral connectWithTimeout:kDeviceConnectTimeout completion:^(NSError *error) {
			[peripheral discoverServicesWithCompletion:^(NSArray *services, NSError *error) {
				for (LGService *service in services) {
					if ([[service.UUIDString uppercaseString] isEqualToString:TEMPO_CUSTOM]) {
						[service discoverCharacteristicsWithCompletion:^(NSArray *characteristics, NSError *error) {
							LGCharacteristic *wcChar;
							LGCharacteristic *dataChar;
							LGCharacteristic *timeSyncChar;
							for (LGCharacteristic *characteristic in characteristics) {
								//get time characteristics
								if ([[characteristic.UUIDString uppercaseString] isEqualToString:TEMPO_TS_TEMP]) {
									timeSyncChar = characteristic;
								}
								else if ([[characteristic.UUIDString uppercaseString] isEqualToString:TEMPO_WC_TEMP]) {
									wcChar = characteristic;
								}
								else if ([[characteristic.UUIDString uppercaseString] isEqualToString:TEMPO_DATA_TEMP]) {
									dataChar = characteristic;
								}
							}
							if (wcChar && dataChar && timeSyncChar) {
								[self startDataDownloadWithTimeSyncCharacteristic:timeSyncChar windowCharacteristic:wcChar dataCharacteristic:dataChar];
							}
							else {
								[MBProgressHUD hideAllHUDsForView:self.view animated:NO];
							}
						}];
					}
				}
			}];
		}];
	}
}
@end
