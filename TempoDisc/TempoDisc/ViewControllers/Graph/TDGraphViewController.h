//
//  TDGraphViewController.h
//  TempoDisc
//
//  Created by Nikola Misic on 3/10/16.
//  Copyright © 2016 BlueMaestro. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TDBaseDeviceViewController.h"
@interface TDGraphViewController : TDBaseDeviceViewController

@property (strong, nonatomic) IBOutlet UIView *viewGraphTemperature;
@property (strong, nonatomic) IBOutlet UIView *viewGraphHumidity;
@property (strong, nonatomic) IBOutlet UIView *viewGraphDewPoint;
@property (strong, nonatomic) IBOutlet UILabel *labelReadingType;

- (IBAction)buttonChangeReadingTypeClicked:(UIButton *)sender;
- (IBAction)buttonDayClicked:(UIButton *)sender;
- (IBAction)buttonWeekClicked:(UIButton *)sender;
- (IBAction)buttonMonthClicked:(UIButton *)sender;
- (IBAction)buttonAllClicked:(UIButton *)sender;

@end
