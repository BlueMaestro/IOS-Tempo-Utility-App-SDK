//
//  TDBaseDeviceViewController.h
//  TempoDisc
//
//  Created by Nikola Misic on 7/26/16.
//  Copyright © 2016 BlueMaestro. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TDBaseDeviceViewController : UIViewController

@property (strong, nonatomic) IBOutlet UILabel *labelDeviceName;
@property (strong, nonatomic) IBOutlet UIView *viewBottomContainer;
@property (strong, nonatomic) IBOutletCollection(UIButton) NSArray *buttonOptions;

- (void)setupView;

- (void)refreshCurrentDevice;
@end
