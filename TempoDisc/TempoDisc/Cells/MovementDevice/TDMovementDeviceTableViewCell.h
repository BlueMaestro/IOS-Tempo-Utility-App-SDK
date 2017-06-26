//
//  TDMovementDeviceTableViewCell.h
//  Tempo Utility
//
//  Created by Nikola Misic on 5/11/17.
//  Copyright © 2017 BlueMaestro. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TDTemperatureDeviceTableViewCell.h"

@interface TDMovementDeviceTableViewCell : TDTemperatureDeviceTableViewCell

@property (strong, nonatomic) IBOutlet UILabel *labelChannelOneTitle;
@property (strong, nonatomic) IBOutlet UILabel *labelChannelOneValue;
@property (strong, nonatomic) IBOutlet UILabel *labelChannelTwoTitle;
@property (strong, nonatomic) IBOutlet UILabel *labelChannelTwoValue;

@property (strong, nonatomic) IBOutlet UILabel *labelPressCountTitle;
@property (strong, nonatomic) IBOutlet UILabel *labelPressCountValue;
@property (strong, nonatomic) IBOutlet UILabel *labelLoggingIntervalTitle;
@property (strong, nonatomic) IBOutlet UILabel *labelLoggingIntervalValue;
@property (strong, nonatomic) IBOutlet UILabel *labelIntervalCountTitle;
@property (strong, nonatomic) IBOutlet UILabel *labelIntervalCountValue;
@end
