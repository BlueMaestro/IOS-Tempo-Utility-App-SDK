//
//  TDDeviceInfoViewController.m
//  TempoDisc
//
//  Created by Nikola Misic on 2/28/16.
//  Copyright © 2016 BlueMaestro. All rights reserved.
//

#import "TDDeviceInfoViewController.h"

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
}
@end
