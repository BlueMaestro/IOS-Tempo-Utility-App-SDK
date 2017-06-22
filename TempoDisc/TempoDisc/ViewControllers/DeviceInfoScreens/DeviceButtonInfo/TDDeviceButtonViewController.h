//
//  TDDeviceButtonViewController.h
//  Tempo Utility
//
//  Created by Nikola Misic on 5/21/17.
//  Copyright © 2017 BlueMaestro. All rights reserved.
//

#import "TDDeviceInfoViewController.h"

@interface TDDeviceButtonViewController : TDDeviceInfoViewController
@property (strong, nonatomic) IBOutlet UILabel *labelButtonCountCurrentValue;
@property (strong, nonatomic) IBOutlet UILabel *labelButtonCountPreviousValue;
@property (strong, nonatomic) IBOutlet UILabel *labelLastPushButtonValue;
@property (strong, nonatomic) IBOutlet UILabel *labelCurrentLogPeriodValue;
@property (strong, nonatomic) IBOutlet UILabel *labelTotalPushesValue;

@end
