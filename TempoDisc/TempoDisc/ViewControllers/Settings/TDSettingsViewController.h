//
//  TDSettingsViewController.h
//  TempoDisc
//
//  Created by Nikola Misic on 3/14/16.
//  Copyright © 2016 BlueMaestro. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TDSettingsViewController : UIViewController

@property (strong, nonatomic) IBOutlet UIButton *buttonBuzz;

- (IBAction)buttonBuzzClicked:(UIButton *)sender;

@end
