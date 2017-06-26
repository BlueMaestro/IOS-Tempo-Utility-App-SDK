//
//  TDPressureDeviceTableViewCell.h
//  Tempo Utility
//
//  Created by Nikola Misic on 2/15/17.
//  Copyright © 2017 BlueMaestro. All rights reserved.
//

#import "TDDeviceTableViewCell.h"

@interface TDPressureDeviceTableViewCell : TDDeviceTableViewCell

@property (strong, nonatomic) IBOutlet UILabel *labelPressureTitle;
@property (strong, nonatomic) IBOutlet UILabel *labelPressureUnit;
@property (strong, nonatomic) IBOutlet UILabel *labelPressureValue;
@end
