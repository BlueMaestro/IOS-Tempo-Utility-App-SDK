//
//  TDDeviceInfoViewController.h
//  TempoDisc
//
//  Created by Nikola Misic on 2/28/16.
//  Copyright © 2016 BlueMaestro. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TDDeviceInfoViewController : UIViewController

@property (strong, nonatomic) IBOutlet UILabel *labelDeviceName;
@property (strong, nonatomic) IBOutlet UILabel *labelTemperatureValue;
@property (strong, nonatomic) IBOutlet UILabel *labelHumidityValue;
@property (strong, nonatomic) IBOutlet UILabel *labelLastDownloadTimestamp;

@property (strong, nonatomic) IBOutlet UIButton *buttonDownload;

- (IBAction)buttonDownloadClicked:(UIButton *)sender;

@end
