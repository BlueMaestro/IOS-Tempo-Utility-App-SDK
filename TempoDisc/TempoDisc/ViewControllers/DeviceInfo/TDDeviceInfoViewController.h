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

//Buttons at bottom
@property (strong, nonatomic) IBOutlet UIButton *graphButton;
@property (strong, nonatomic) IBOutlet UIButton *buttonDownload;
@property (strong, nonatomic) IBOutlet UIButton *buttonUART;

//Any alerts
@property (strong, nonatomic) IBOutlet UILabel *labelAlerts;

/**
 *	UI update components
 **/
@property (strong, nonatomic) IBOutletCollection(UIImageView) NSArray *boxImageViews;//colored views for image resize
@property (strong, nonatomic) IBOutletCollection(NSLayoutConstraint) NSArray *boxHeightConstraints;//height constraints for image views
@property (strong, nonatomic) IBOutletCollection(NSLayoutConstraint) NSArray *boxWidthConstraints;//width contstraints for image views
@property (strong, nonatomic) IBOutletCollection(NSLayoutConstraint) NSArray *containerHeightConstraints;//individual containter height constraints
@property (strong, nonatomic) IBOutletCollection(UILabel) NSArray *boxLabels;//labels whose fonts need to be increased for ipad
@property (strong, nonatomic) IBOutletCollection(NSLayoutConstraint) NSArray *topOffsetContraints;//top constraints for labels in image views for ipad
@property (strong, nonatomic) IBOutletCollection(NSLayoutConstraint) NSArray *buttonWidthConstraints;//bottom button constraints
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *bottomMenuHeight;



//box image views that need image resize
/*
@property (strong, nonatomic) IBOutletCollection(UIImageView) NSArray *upperBoxImageViews;
@property (strong, nonatomic) IBOutletCollection(UIImageView) NSArray *middleBoxImageViews;
@property (strong, nonatomic) IBOutletCollection(UIImageView) NSArray *lowerBoxImageViews;
*/

//device info view
@property (strong, nonatomic) IBOutlet UILabel *labelDeviceUUID;
@property (strong, nonatomic) IBOutlet UILabel *labelDeviceVersion;
@property (strong, nonatomic) IBOutlet UILabel *labelDeviceBatteryValue;
@property (strong, nonatomic) IBOutlet UILabel *labelDeviceRSSIValue;
@property (strong, nonatomic) IBOutlet UILabel *labelDeviceID;
@property (strong, nonatomic) IBOutlet UILabel *labelDeviceIDValue;
@property (weak, nonatomic) IBOutlet UIImageView *RSSIImage;
@property (strong, nonatomic) IBOutlet UIImageView *batteryImage;

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



/**
 *	Actions
 **/
- (IBAction)buttonGraphClicked:(UIButton *)sender;

- (IBAction)buttonConsoleClicked:(UIButton *)sender;


@end
