//
//  TDDeviceTableContainer.h
//  TempoDisc
//
//  Created by Nikola Misic on 7/26/16.
//  Copyright © 2016 BlueMaestro. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TDBaseDeviceViewController.h"
@interface TDDeviceTableContainer : TDBaseDeviceViewController

@property (strong, nonatomic) IBOutletCollection(UIButton) NSArray *buttonsBottomMenu;
@property (strong, nonatomic) IBOutlet UIButton *buttonReadingType;
@property (strong, nonatomic) IBOutlet UIView *viewBottomMenuContainer;

- (IBAction)buttonExportPdfClicked:(UIButton *)sender;
- (IBAction)buttonExportCSVClicked:(UIButton *)sender;
- (IBAction)buttonChangeReadingTypeClicked:(UIButton *)sender;

@end
