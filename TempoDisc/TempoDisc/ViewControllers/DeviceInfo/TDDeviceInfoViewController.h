//
//  TDDeviceInfoViewController.h
//  TempoDisc
//
//  Created by Nikola Misic on 2/28/16.
//  Copyright © 2016 BlueMaestro. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TDBaseDeviceViewController.h"
@interface TDDeviceInfoViewController : TDBaseDeviceViewController

@property (strong, nonatomic) IBOutlet UILabel *labelTemperatureValue;
@property (strong, nonatomic) IBOutlet UILabel *labelHumidityValue;
@property (strong, nonatomic) IBOutlet UILabel *labelLastDownloadTimestamp;
@property (strong, nonatomic) IBOutlet UIButton *buttonUART;
@property (strong, nonatomic) IBOutlet UILabel *labelUUID;
@property (strong, nonatomic) IBOutlet UILabel *labelVersion;
@property (strong, nonatomic) IBOutlet UILabel *labelRSSI;
@property (strong, nonatomic) IBOutlet UILabel *labelAlerts;

@property (strong, nonatomic) IBOutlet UIButton *buttonDownload;

- (IBAction)buttonDownloadClicked:(UIButton *)sender;


@end
