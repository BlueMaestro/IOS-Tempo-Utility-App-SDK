//
//  TDDeviceLuminosityInfoViewController.h
//  Tempo Utility
//
//  Created by Nikola Misic on 6/22/17.
//  Copyright © 2017 BlueMaestro. All rights reserved.
//

#import "TDDevicePressureInfoViewController.h"

@interface TDDeviceLuminosityInfoViewController : TDDevicePressureInfoViewController

@property (strong, nonatomic) IBOutlet UILabel *labalCurrentLuminosityLevel;
@property (strong, nonatomic) IBOutlet UILabel *labelCurrentLuminosityLevelValue;

@end
