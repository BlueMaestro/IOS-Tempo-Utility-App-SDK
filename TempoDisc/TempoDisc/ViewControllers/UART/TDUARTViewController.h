//
//  TDUARTViewController.h
//  TempoDisc
//
//  Created by Nikola Misic on 7/7/16.
//  Copyright © 2016 BlueMaestro. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TDUARTViewController : UIViewController <UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) IBOutlet UITextField *textFieldMessage;
@property (strong, nonatomic) IBOutlet UIButton *buttonSendMessage;
@property (strong, nonatomic) IBOutlet UIButton *buttonConnect;

@property (strong, nonatomic) IBOutlet UITableView *tableViewLog;

- (IBAction)buttonSendMessageClicked:(UIButton *)sender;
- (IBAction)buttonConnectClicked:(UIButton *)sender;

@end
