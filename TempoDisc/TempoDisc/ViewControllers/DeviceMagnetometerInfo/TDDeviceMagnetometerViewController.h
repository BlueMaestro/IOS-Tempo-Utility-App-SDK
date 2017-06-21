//
//  TDDeviceMagnetometerViewController.h
//  Tempo Utility
//
//  Created by Nikola Misic on 6/21/17.
//  Copyright © 2017 BlueMaestro. All rights reserved.
//

#import "TDDevicePressureInfoViewController.h"

@interface TDDeviceMagnetometerViewController : TDDevicePressureInfoViewController

@property (strong, nonatomic) IBOutlet UILabel *labelStatusValue;
@property (strong, nonatomic) IBOutlet UILabel *labelNumberOfOpenEventsValue;
@property (strong, nonatomic) IBOutlet UILabel *labelNumberOfOccuredInLoggingPeriodValue;
@property (strong, nonatomic) IBOutlet UILabel *labelTotalEventsValue;

@end
