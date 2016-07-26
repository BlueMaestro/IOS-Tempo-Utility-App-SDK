//
//  TDSettingsViewController.h
//  TempoDisc
//
//  Created by Nikola Misic on 3/14/16.
//  Copyright © 2016 BlueMaestro. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TDBaseDeviceViewController.h"
@interface TDSettingsViewController : TDBaseDeviceViewController

@property (strong, nonatomic) IBOutlet UIButton *buttonBuzz;
@property (strong, nonatomic) IBOutlet UISwitch *switchTemperatureUnit;
@property (strong, nonatomic) IBOutlet UIDatePicker *datePickerFrequency;
@property (strong, nonatomic) IBOutlet UIButton *buttonWriteFrequency;

- (IBAction)buttonBuzzClicked:(UIButton *)sender;
- (IBAction)switchTemperatureUnitValueChanged:(UISwitch *)sender;
- (IBAction)datePickerFrequencyValueChanged:(UIDatePicker *)sender;
- (IBAction)buttonWriteFrequencyClicked:(UIButton *)sender;

@end
