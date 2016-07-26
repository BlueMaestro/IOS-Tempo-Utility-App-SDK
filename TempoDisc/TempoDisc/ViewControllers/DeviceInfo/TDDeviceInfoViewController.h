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
@property (strong, nonatomic) IBOutlet UIButton *buttonUART;
@property (strong, nonatomic) IBOutlet UILabel *labelUUID;
@property (strong, nonatomic) IBOutlet UILabel *labelVersion;
@property (strong, nonatomic) IBOutlet UILabel *labelRSSI;
@property (strong, nonatomic) IBOutlet UILabel *labelAlerts;

@property (strong, nonatomic) IBOutlet UIButton *buttonDownload;
@property (strong, nonatomic) IBOutlet UIView *viewBottomContainer;

- (IBAction)buttonDownloadClicked:(UIButton *)sender;

@property (strong, nonatomic) IBOutletCollection(UIButton) NSArray *buttonOptions;
@end
