//
//  TDTemperatureDevoceTableViewCell.h
//  Tempo Utility
//
//  Created by Nikola Misic on 5/8/17.
//  Copyright © 2017 BlueMaestro. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TDPressureDeviceTableViewCell.h"

@interface TDTemperatureDevoceTableViewCell : TDPressureDeviceTableViewCell

@property (strong, nonatomic) IBOutlet UILabel *labelMode;
@property (strong, nonatomic) IBOutlet UILabel *labelModeValue;
@property (strong, nonatomic) IBOutlet UILabel *labelUnits;
@property (strong, nonatomic) IBOutlet UILabel *labelUnitsValue;
@property (strong, nonatomic) IBOutlet UILabel *labelThresholdBreaches;
@property (strong, nonatomic) IBOutlet UILabel *labelThresholdBreachesValue;
@end
