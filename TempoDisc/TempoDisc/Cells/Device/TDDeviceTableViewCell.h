//
//  TDDeviceTableViewCell.h
//  TempoDisc
//
//  Created by Nikola Misic on 2/28/16.
//  Copyright © 2016 BlueMaestro. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TDDeviceTableViewCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UILabel *labelDeviceName;
@property (strong, nonatomic) IBOutlet UILabel *labelDeviceBattery;
@property (strong, nonatomic) IBOutlet UILabel *labelDeviceVersion;
@property (strong, nonatomic) IBOutlet UILabel *labelTemperatureValue;
@property (strong, nonatomic) IBOutlet UILabel *labelHumidityValue;


@end
