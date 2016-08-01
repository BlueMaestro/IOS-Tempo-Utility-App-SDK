//
//  TDDeviceDataTableViewController.h
//  TempoDisc
//
//  Created by Nikola Misic on 2/28/16.
//  Copyright © 2016 BlueMaestro. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TDDeviceDataTableViewController : UITableViewController

@property (nonatomic, assign) TempoReadingType currentReadingType;

- (void)changeReadingType:(TempoReadingType)type;

@end
