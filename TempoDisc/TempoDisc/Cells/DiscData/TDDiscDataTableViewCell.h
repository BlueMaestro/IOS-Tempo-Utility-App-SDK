//
//  TDDiscDataTableViewCell.h
//  Tempo Utility
//
//  Created by Nikola Misic on 10/10/16.
//  Copyright © 2016 BlueMaestro. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TDDiscDataTableViewCell : UITableViewCell
@property (strong, nonatomic) IBOutlet UILabel *labelDate;
@property (strong, nonatomic) IBOutlet UILabel *labelRecordNumber;
@property (strong, nonatomic) IBOutlet UILabel *labelTemperature;
@property (strong, nonatomic) IBOutlet UILabel *labelHumidity;
@property (strong, nonatomic) IBOutlet UILabel *labelDewPoint;

@property (strong, nonatomic) IBOutlet UILabel *labelDateValue;
@property (strong, nonatomic) IBOutlet UILabel *labelRecordNumberValue;
@property (strong, nonatomic) IBOutlet UILabel *labelTemperatureValue;
@property (strong, nonatomic) IBOutlet UILabel *labelHumidityValue;
@property (strong, nonatomic) IBOutlet UILabel *labelDewPointValue;
@end
