//
//  TDDeviceInfoViewController.m
//  TempoDisc
//
//  Created by Nikola Misic on 2/28/16.
//  Copyright © 2016 BlueMaestro. All rights reserved.
//

#import "TDDeviceInfoViewController.h"
#import <LGBluetooth/LGBluetooth.h>

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

@interface TDDeviceInfoViewController ()

@property (nonatomic, strong) NSDateFormatter *formatterLastDownload;

@end

@implementation TDDeviceInfoViewController

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

#pragma mark - Actions

- (IBAction)buttonDownloadClicked:(UIButton *)sender {
	[MBProgressHUD showHUDAddedTo:self.view animated:YES];
	LGPeripheral *peripheral = [TDDefaultDevice sharedDevice].selectedDevice.peripheral;
	if (peripheral) {
		[peripheral connectWithTimeout:kDeviceConnectTimeout completion:^(NSError *error) {
			[peripheral discoverServicesWithCompletion:^(NSArray *services, NSError *error) {
				for (LGService *service in services) {
					if ([service.UUIDString isEqualToString:@"180f"]) {
						[service discoverCharacteristicsWithCompletion:^(NSArray *characteristics, NSError *error) {
							for (LGCharacteristic *characteristic in characteristics) {
								if ([characteristic.UUIDString isEqualToString:@"2a19"]) {
									[characteristic readValueWithBlock:^(NSData *data, NSError *error) {
										uint8_t value;
										[data getBytes:&value length:1];
										NSNumber *valueBattery = [NSNumber numberWithUnsignedShort:value];
										[TDDefaultDevice sharedDevice].selectedDevice.battery = [NSDecimalNumber decimalNumberWithDecimal:[valueBattery decimalValue]];
										[peripheral disconnectWithCompletion:nil];
										[MBProgressHUD hideAllHUDsForView:self.view animated:NO];
									}];
								}
							}
						}];
					}
				}
			}];
		}];
	}
}
@end
