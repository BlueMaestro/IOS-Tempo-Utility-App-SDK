//
//  TDDevicePressureInfoViewController.h
//  Tempo Utility
//
//  Created by Nikola Misic on 2/15/17.
//  Copyright © 2017 BlueMaestro. All rights reserved.
//

#import "TDDeviceInfoViewController.h"

@interface TDDevicePressureInfoViewController : TDDeviceInfoViewController

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *constraintInfoContainerHeight;

@property (strong, nonatomic) IBOutlet UILabel *labelPressureTitle;
@property (strong, nonatomic) IBOutlet UILabel *labelPressureUnit;
@property (strong, nonatomic) IBOutlet UILabel *labelPressureCurrentValue;
@property (strong, nonatomic) IBOutlet UILabel *labelPressureHighestDayLogged;
@property (strong, nonatomic) IBOutlet UILabel *labelPressureAverageDayLogged;
@property (strong, nonatomic) IBOutlet UILabel *labelPressureLowestDayLogged;

@end
