//
//  TDMagnetometerDeviceTableViewCell.h
//  Tempo Utility
//
//  Created by Nikola Misic on 6/21/17.
//  Copyright © 2017 BlueMaestro. All rights reserved.
//

#import "TDTemperatureDeviceTableViewCell.h"

@interface TDMagnetometerDeviceTableViewCell : TDTemperatureDeviceTableViewCell

@property (strong, nonatomic) IBOutlet UILabel *labelStatus;
@property (strong, nonatomic) IBOutlet UILabel *labelStatusValue;
@property (strong, nonatomic) IBOutlet UIImageView *imageViewStatusBox;

@end
