//
//  TDDeviceTableViewCell.h
//  TempoDisc
//
//  Created by Nikola Misic on 2/28/16.
//  Copyright © 2016 BlueMaestro. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum : NSInteger {
	TempoBatteryStatusNone,
	TempoBatteryStatusGood
} TempoBatteryStatus;

@interface TDDeviceTableViewCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UILabel *labelDeviceName;
@property (strong, nonatomic) IBOutlet UILabel *labelDeviceBattery;
@property (strong, nonatomic) IBOutlet UILabel *labelDeviceVersion;
@property (strong, nonatomic) IBOutlet UILabel *labelTemperatureValue;
@property (strong, nonatomic) IBOutlet UILabel *labelHumidityValue;
@property (strong, nonatomic) IBOutlet UILabel *labelRSSIValue;
@property (strong, nonatomic) IBOutlet UILabel *labelDeviceUUID;
@property (strong, nonatomic) IBOutlet UILabel *labelDeviceUUIDValue;
@property (strong, nonatomic) IBOutlet UILabel *labelDeviceVersionValue;
@property (strong, nonatomic) IBOutlet UILabel *labelDeviceRSSIValue;
@property (strong, nonatomic) IBOutlet UILabel *labelDeviceBatteryValue;
@property (strong, nonatomic) IBOutlet UILabel *labelCurrentDewPoint;
@property (strong, nonatomic) IBOutlet UILabel *labelCurrentDewPointValue;

- (void)setupBatteryStatus:(TempoBatteryStatus)status;

@end
