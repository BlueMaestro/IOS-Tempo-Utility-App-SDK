//
//  TDLuminosityDeviceTableViewCell.h
//  Tempo Utility
//
//  Created by Nikola Misic on 6/22/17.
//  Copyright © 2017 BlueMaestro. All rights reserved.
//

#import "TDTemperatureDeviceTableViewCell.h"

@interface TDLuminosityDeviceTableViewCell : TDTemperatureDeviceTableViewCell

@property (strong, nonatomic) IBOutlet UILabel *labelLuminosity;
@property (strong, nonatomic) IBOutlet UILabel *labelLuminosityValue;

@end
