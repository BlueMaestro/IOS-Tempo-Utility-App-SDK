//
//  TDUARTViewController.h
//  TempoDisc
//
//  Created by Nikola Misic on 7/7/16.
//  Copyright © 2016 BlueMaestro. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TDBaseDeviceViewController.h"

typedef void(^WriteCompletion)(BOOL success, NSError* error);

@interface TDUARTViewController : TDBaseDeviceViewController <UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) IBOutlet UITextField *textFieldMessage;
@property (strong, nonatomic) IBOutlet UIButton *buttonSendMessage;
@property (strong, nonatomic) IBOutlet UIButton *buttonConnect;

@property (strong, nonatomic) IBOutlet UIButton *buttonDeviceInfo;
@property (strong, nonatomic) IBOutlet UIButton *buttonAlarmInfo;
@property (strong, nonatomic) IBOutlet UIButton *buttonStreamData;


@property (strong, nonatomic) IBOutlet UITableView *tableViewLog;
@property (strong, nonatomic) IBOutlet UIScrollView *scrollViewMain;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *constraintScrollViewBottom;

@property (strong, nonatomic) NSString *option;//option with which the screen was opened

@property (weak, nonatomic) MBProgressHUD *hud;

- (IBAction)buttonSendMessageClicked:(UIButton *)sender;
- (IBAction)buttonConnectClicked:(UIButton *)sender;
- (IBAction)buttonHelperClicked:(UIButton *)sender;

//BLE interaction
- (void)connectAndWrite:(NSString*)data;
- (void)connectAndWrite:(NSString *)data withCompletion:(WriteCompletion)completion;

- (void)handleDeviceDataReceive:(NSData*)data error:(NSError*)error;
- (void)handleDisconnectNotification:(NSNotification*)note;
@end
