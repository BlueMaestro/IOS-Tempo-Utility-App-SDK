//
//  TDDeviceListTableViewController.h
//  TempoDisc
//
//  Created by Nikola Misic on 2/28/16.
//  Copyright © 2016 BlueMaestro. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TDDeviceListTableViewController : UITableViewController

@property (nonatomic, assign) BOOL scanning;

- (void)scanForDevices;

@end
