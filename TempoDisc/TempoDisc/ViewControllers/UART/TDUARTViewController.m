//
//  TDUARTViewController.m
//  TempoDisc
//
//  Created by Nikola Misic on 7/7/16.
//  Copyright © 2016 BlueMaestro. All rights reserved.
//

#import "TDUARTViewController.h"
#import <LGBluetooth/LGBluetooth.h>
#import <CoreBluetooth/CoreBluetooth.h>

//for testing on tempo device
/*#define uartServiceUUIDString			@"20652000-02F3-4F75-848F-323AC2A6AF8A"//TEMPO_CUSTOM
#define uartRXCharacteristicUUIDString	@"20652010-02F3-4F75-848F-323AC2A6AF8A"//TEMPO NAME
#define uartTXCharacteristicUUIDString	@"20652012-02F3-4F75-848F-323AC2A6AF8A"//TEMPO iBEACON*/

//actual nRF service and characteristic UUIDs
#define uartServiceUUIDString			@"6E400001-B5A3-F393-E0A9-E50E24DCCA9E"
#define uartRXCharacteristicUUIDString	@"6E400002-B5A3-F393-E0A9-E50E24DCCA9E"
#define uartTXCharacteristicUUIDString	@"6E400003-B5A3-F393-E0A9-E50E24DCCA9E"

#define kDeviceConnectTimeout			10.0

@interface TDUARTViewController ()

@property (nonatomic, strong) NSMutableArray *dataSourceLogMessages;
@property (nonatomic, strong) LGCharacteristic *writeCharacteristic;

@property (nonatomic, strong) NSString *dataToSend;

@end

@implementation TDUARTViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	_dataSourceLogMessages = [NSMutableArray array];
	[self setupView];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDisconnectNotification:) name:kLGPeripheralDidDisconnect object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardHideNotification:) name:UIKeyboardWillHideNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardShowNotification:) name:UIKeyboardWillShowNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:kLGPeripheralDidDisconnect object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
	[[TDDefaultDevice sharedDevice].selectedDevice.peripheral disconnectWithCompletion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - Private methods

- (void)setupView {
	_tableViewLog.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
	_tableViewLog.rowHeight = UITableViewAutomaticDimension;
	_tableViewLog.estimatedRowHeight = 44.0;
	
	_textFieldMessage.layer.cornerRadius = 8.0;
	_textFieldMessage.clipsToBounds = YES;
	_textFieldMessage.layer.borderWidth = 2;
	_textFieldMessage.layer.borderColor = [UIColor blueMaestroBlue].CGColor;
	_textFieldMessage.textColor = [UIColor blueMaestroBlue];
	_textFieldMessage.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, _textFieldMessage.frame.size.height)];
	_textFieldMessage.leftViewMode = UITextFieldViewModeAlways;
	_textFieldMessage.rightView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, _textFieldMessage.frame.size.height)];
	_textFieldMessage.rightViewMode = UITextFieldViewModeAlways;
	
	_buttonConnect.layer.cornerRadius = 8.0;
	_buttonConnect.clipsToBounds = YES;
	_buttonConnect.layer.borderColor = [UIColor blueMaestroBlue].CGColor;
	_buttonConnect.layer.borderWidth = 2;

	_buttonSendMessage.layer.cornerRadius = 8.0;
	_buttonSendMessage.clipsToBounds = YES;
	_buttonSendMessage.layer.borderColor = [UIColor blueMaestroBlue].CGColor;
	_buttonSendMessage.layer.borderWidth = 2;
	
	_viewBottomContainer.layer.borderWidth = 1;
	_viewBottomContainer.layer.borderColor = [UIColor botomBarSeparatorGrey].CGColor;
	
//	_labelDeviceName.text = [TDDefaultDevice sharedDevice].selectedDevice.name;
}

- (void)handleDisconnectNotification:(NSNotification*)note {
	[self addLogMessage:[NSString stringWithFormat:@"Device disconnected: %@", note.userInfo]];
	_writeCharacteristic = nil;
}

- (void)handleKeyboardShowNotification:(NSNotification*)note {
	NSDictionary *userInfo = [note userInfo];
	CGSize size = [[userInfo objectForKey: UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
	_constraintScrollViewBottom.constant = size.height;
	__weak typeof(self) weakself = self;
	[UIView animateWithDuration:0.3 animations:^{
		[weakself.view layoutIfNeeded];
	}];
	[_scrollViewMain scrollRectToVisible:CGRectMake(_scrollViewMain.contentSize.width - 1,_scrollViewMain.contentSize.height - 1, 1, 1) animated:YES];
}

- (void)handleKeyboardHideNotification:(NSNotification*)note {
	_constraintScrollViewBottom.constant = 0;
}

- (void)addLogMessage:(NSString*)message {
	[_dataSourceLogMessages addObject:message];
	NSIndexPath *targetIndexPath = [NSIndexPath indexPathForRow:_dataSourceLogMessages.count-1 inSection:0];
	[_tableViewLog insertRowsAtIndexPaths:@[targetIndexPath] withRowAnimation:UITableViewRowAnimationBottom];
	[_tableViewLog scrollToRowAtIndexPath:targetIndexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
}

- (void)setupDevice {
	[self addLogMessage:@"Connecting to device..."];
	__weak typeof(self) weakself = self;
	[[TDDefaultDevice sharedDevice].selectedDevice.peripheral connectWithTimeout:kDeviceConnectTimeout completion:^(NSError *error) {
		if (!error) {
			[weakself addLogMessage:@"Connected to device"];
			[weakself addLogMessage:@"Discovering device services..."];
			[[TDDefaultDevice sharedDevice].selectedDevice.peripheral discoverServicesWithCompletion:^(NSArray *services, NSError *error2) {
				if (!error2) {
					[weakself addLogMessage:@"Discovered services"];
					LGService *uartService;
					for (LGService* service in services) {
						if ([[service.UUIDString uppercaseString] isEqualToString:uartServiceUUIDString]) {
							uartService = service;
							[weakself addLogMessage:[NSString stringWithFormat:@"Found UART service: %@", service.UUIDString]];
							[weakself addLogMessage:@"Discovering characteristics..."];
							[service discoverCharacteristicsWithCompletion:^(NSArray *characteristics, NSError *error3) {
								if (!error3) {
									[weakself addLogMessage:@"Discovered characteristics"];
									LGCharacteristic *readCharacteristic;
									for (LGCharacteristic *characteristic in characteristics) {
										if ([[characteristic.UUIDString uppercaseString] isEqualToString:uartTXCharacteristicUUIDString]) {
											[weakself addLogMessage:[NSString stringWithFormat:@"Found TX characteristic %@", characteristic.UUIDString]];
											readCharacteristic = characteristic;
											/*CBMutableCharacteristic *noteCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:readCharacteristic.UUIDString] properties:CBCharacteristicPropertyNotify+CBCharacteristicPropertyRead
																														  value:nil permissions:CBAttributePermissionsReadable|CBAttributePermissionsWriteable];
											LGCharacteristic *characteristicForNotification = [[LGCharacteristic alloc] initWithCharacteristic:noteCharacteristic];*/
											[weakself addLogMessage:@"Subscribing for TX characteristic notifications"];
											[characteristic setNotifyValue:YES completion:^(NSError *error4) {
												if (!error4) {
													[weakself addLogMessage:@"Subscribed for TX characteristic notifications"];
												}
												else {
													[weakself addLogMessage:[NSString stringWithFormat:@"Error subscribing for TX characteristic: %@", error4]];
												}
											} onUpdate:^(NSData *data, NSError *error5) {
												if (!error5) {
													[weakself addLogMessage:[NSString stringWithFormat:@"New data from TX characteristic: %@", data]];
												}
												else {
													[weakself addLogMessage:[NSString stringWithFormat:@"Error on updating TX data: %@", error5]];
												}
											}];
										}
										else if ([[characteristic.UUIDString uppercaseString] isEqualToString:uartRXCharacteristicUUIDString]) {
											[weakself addLogMessage:[NSString stringWithFormat:@"Found RX characteristic %@", characteristic.UUIDString]];
											weakself.writeCharacteristic = characteristic;
										}
									}
									if (!readCharacteristic) {
										[weakself addLogMessage:@"Could not find TX characteristic"];
									}
									if (!weakself.writeCharacteristic) {
										[weakself addLogMessage:@"Could not find RX characteristic"];
									}
									if (weakself.writeCharacteristic && weakself.dataToSend) {
										[weakself writeData:weakself.dataToSend toCharacteristic:weakself.writeCharacteristic];
										weakself.dataToSend = nil;
									}
								}
								else {
									[weakself addLogMessage:[NSString stringWithFormat:@"Error discovering device characteristics: %@", error3]];
								}
							}];
							break;
						}
					}
					if (!uartService) {
						[weakself addLogMessage:@"Failed to found UART service"];
					}
				}
				else {
					[weakself addLogMessage:[NSString stringWithFormat:@"Error discovering device services: %@", error2]];
				}
			}];
		}
		else {
			[weakself addLogMessage:[NSString stringWithFormat:@"Error connecting to device: %@", error]];
		}
	}];
}

- (void)writeData:(NSString*)data toCharacteristic:(LGCharacteristic*)characteristic {
	[self addLogMessage:[NSString stringWithFormat:@"Writing data: %@ to characteristic: %@", data, characteristic.UUIDString]];
	__weak typeof(self) weakself = self;
	[characteristic writeValue:[data dataUsingEncoding:NSUTF8StringEncoding] completion:^(NSError *error) {
		if (!error) {
			[weakself addLogMessage:@"Sucessefully wrote data to write characteristic"];
		}
		else {
			[weakself addLogMessage:[NSString stringWithFormat:@"Error writing data to characteristic: %@", error]];
		}
	}];
}

#pragma mark - Public methods

#pragma mark - Actions

- (IBAction)buttonSendMessageClicked:(UIButton *)sender {
	[_textFieldMessage resignFirstResponder];
	if (_writeCharacteristic) {
		[self writeData:_textFieldMessage.text toCharacteristic:_writeCharacteristic];
	}
	else {
		[self addLogMessage:@"Write characteristic not found. Recconnecting..."];
		_dataToSend = _textFieldMessage.text;
		[self setupDevice];
	}
}

- (IBAction)buttonConnectClicked:(UIButton *)sender {
	[self setupDevice];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return _dataSourceLogMessages.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cellLog" forIndexPath:indexPath];
	[(UILabel*)[cell viewWithTag:545] setText:_dataSourceLogMessages[indexPath.row]];
	
	return cell;
}

#pragma mark - UITableViewDelegate

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
	return YES;
}

@end
