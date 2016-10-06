//
//  TDDevicesContainerViewController.h
//  TempoDisc
//
//  Created by Nikola Misic on 7/26/16.
//  Copyright © 2016 BlueMaestro. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TDBaseDeviceViewController.h"
#import "TDDeviceListTableViewController.h"

@interface TDDevicesContainerViewController : TDBaseDeviceViewController
@property (strong, nonatomic) IBOutlet UILabel *labelScanStatus;
@property (strong, nonatomic) IBOutlet UIButton *buttonStartScan;
@property (nonatomic, strong) TDDeviceListTableViewController *controllerDeviceList;

- (IBAction)buttonStartScanClicked:(UIButton *)sender;
- (void)setupView;
@end
