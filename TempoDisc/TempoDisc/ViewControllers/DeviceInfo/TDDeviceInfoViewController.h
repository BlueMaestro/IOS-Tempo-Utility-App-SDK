//
//  TDDeviceInfoViewController.h
//  TempoDisc
//
//  Created by Nikola Misic on 2/28/16.
//  Copyright © 2016 BlueMaestro. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TDBaseDeviceViewController.h"

@interface TDDeviceInfoViewController : TDBaseDeviceViewController


@property (strong, nonatomic) IBOutlet UIButton *graphButton;
@property (strong, nonatomic) IBOutlet UILabel *labelTemperatureValue;
@property (strong, nonatomic) IBOutlet UILabel *labelHumidityValue;
@property (strong, nonatomic) IBOutlet UILabel *labelLastDownloadTimestamp;
@property (strong, nonatomic) IBOutlet UIButton *buttonUART;
@property (strong, nonatomic) IBOutlet UILabel *labelUUID;
@property (strong, nonatomic) IBOutlet UILabel *labelVersion;
@property (strong, nonatomic) IBOutlet UILabel *labelRSSI;
@property (strong, nonatomic) IBOutlet UILabel *labelAlerts;
@property (weak, nonatomic) IBOutlet UIImageView *RSSIImage;
@property (strong, nonatomic) IBOutlet UIImageView *batteryImage;

@property (strong, nonatomic) IBOutlet UIButton *buttonDownload;

/**
 *	UI update components
 **/

//box image views that need image resize
@property (strong, nonatomic) IBOutletCollection(UIImageView) NSArray *boxImageViews;


//device info view
@property (strong, nonatomic) IBOutlet UILabel *labelDeviceUUID;
@property (strong, nonatomic) IBOutlet UILabel *labelDeviceVersion;
@property (strong, nonatomic) IBOutlet UILabel *labelDeviceBatteryValue;
@property (strong, nonatomic) IBOutlet UILabel *labelDeviceRSSIValue;
@property (strong, nonatomic) IBOutlet UILabel *labelDeviceID;
@property (strong, nonatomic) IBOutlet UILabel *labelDeviceIDValue;

@property (strong, nonatomic) IBOutlet UIImageView *imageViewBatteryStatus;

//record dates view
@property (strong, nonatomic) IBOutlet UILabel *labelFirstLogDateValue;
@property (strong, nonatomic) IBOutlet UILabel *labelLastDownloadValue;

//current view
@property (strong, nonatomic) IBOutlet UILabel *labelCurrentDeviceTemperatureUnit;
@property (strong, nonatomic) IBOutlet UILabel *labelCurrentDeviceTemperatureValue;
@property (strong, nonatomic) IBOutlet UILabel *labelCurrentDeviceHumidityValue;
@property (strong, nonatomic) IBOutlet UILabel *labelCurrentDeviceDewPointUnit;
@property (strong, nonatomic) IBOutlet UILabel *labelCurrentDeviceDewPointValue;

//last 24 hours view
@property (strong, nonatomic) IBOutlet UILabel *labelLast24DeviceTemperatureHighValue;
@property (strong, nonatomic) IBOutlet UILabel *labelLast24DeviceTemperatureAverageValue;
@property (strong, nonatomic) IBOutlet UILabel *labelLast24DeviceTemperatureLowValue;
@property (strong, nonatomic) IBOutlet UILabel *labelLast24DeviceHumidityHighValue;
@property (strong, nonatomic) IBOutlet UILabel *labelLast24DeviceHumidityAverageValue;
@property (strong, nonatomic) IBOutlet UILabel *labelLast24DeviceHumidityLowValue;
@property (strong, nonatomic) IBOutlet UILabel *labelLast24DeviceDewPointHighValue;
@property (strong, nonatomic) IBOutlet UILabel *labelLast24DeviceDewPointAverageValue;
@property (strong, nonatomic) IBOutlet UILabel *labelLast24DeviceDewPointLowValue;

//highest and lowest view
@property (strong, nonatomic) IBOutlet UILabel *labelHighLowDeviceTemperatureHighValue;
@property (strong, nonatomic) IBOutlet UILabel *labelHighLowDeviceTemperatureLowValue;
@property (strong, nonatomic) IBOutlet UILabel *labelHighLowDeviceHumidityHighValue;
@property (strong, nonatomic) IBOutlet UILabel *labelHighLowDeviceHumidityLowValue;
@property (strong, nonatomic) IBOutlet UILabel *labelHighLowDeviceDewPointHighValue;
@property (strong, nonatomic) IBOutlet UILabel *labelHighLowDeviceDewPointLowValue;



/**
 *	Actions
 **/
- (IBAction)buttonGraphClicked:(UIButton *)sender;

- (IBAction)buttonConsoleClicked:(UIButton *)sender;


@end
