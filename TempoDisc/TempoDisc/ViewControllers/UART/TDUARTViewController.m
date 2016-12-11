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
#import "LogMessage.h"

//for testing on tempo device
/*#define uartServiceUUIDString			@"20652000-02F3-4F75-848F-323AC2A6AF8A"//TEMPO_CUSTOM
#define uartRXCharacteristicUUIDString	@"20652010-02F3-4F75-848F-323AC2A6AF8A"//TEMPO NAME
#define uartTXCharacteristicUUIDString	@"20652012-02F3-4F75-848F-323AC2A6AF8A"//TEMPO iBEACON*/

//actual nRF service and characteristic UUIDs
#define uartServiceUUIDString			@"6E400001-B5A3-F393-E0A9-E50E24DCCA9E"
#define uartRXCharacteristicUUIDString	@"6E400002-B5A3-F393-E0A9-E50E24DCCA9E"
#define uartTXCharacteristicUUIDString	@"6E400003-B5A3-F393-E0A9-E50E24DCCA9E"

#define kDeviceReconnectTimeout			2.0

#define kDeviceConnectTimeout			10.0

@interface TDUARTViewController ()

@property (nonatomic, strong) NSMutableArray *dataSourceLogMessages;
@property (nonatomic, strong) LGCharacteristic *writeCharacteristic;
@property (nonatomic, strong) LGCharacteristic *readCharacteristic;

@property (nonatomic, strong) NSString *dataToSend;

@property (nonatomic, assign) BOOL didDisconnect;

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
	[self refreshCurrentDevice];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:kLGPeripheralDidDisconnect object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
	if (_readCharacteristic) {
		[_readCharacteristic setNotifyValue:NO completion:^(NSError *error) {
			[[TDDefaultDevice sharedDevice].selectedDevice.peripheral disconnectWithCompletion:nil];
		}];
	}
	else {
		[[TDDefaultDevice sharedDevice].selectedDevice.peripheral disconnectWithCompletion:nil];
	}
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
	[super setupView];
	_tableViewLog.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
	_tableViewLog.rowHeight = UITableViewAutomaticDimension;
	_tableViewLog.estimatedRowHeight = 44.0;
	
	_textFieldMessage.layer.cornerRadius = 4.0;
	_textFieldMessage.clipsToBounds = YES;
	_textFieldMessage.layer.borderWidth = 1;
	_textFieldMessage.layer.borderColor = [UIColor buttonSeparator].CGColor;
	_textFieldMessage.textColor = [UIColor blackColor];
	_textFieldMessage.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, _textFieldMessage.frame.size.height)];
	_textFieldMessage.leftViewMode = UITextFieldViewModeAlways;
	_textFieldMessage.rightView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, _textFieldMessage.frame.size.height)];
	_textFieldMessage.rightViewMode = UITextFieldViewModeAlways;
	
	_tableViewLog.layer.cornerRadius = 8;
	_tableViewLog.layer.borderWidth = 1;
	_tableViewLog.layer.borderColor = [UIColor buttonSeparator].CGColor;
}

- (void)handleDisconnectNotification:(NSNotification*)note {
	[self addLogMessage:[NSString stringWithFormat:NSLocalizedString(@"Device disconnected from us", nil)] type:LogMessageTypeInbound];
	_writeCharacteristic = nil;
	_didDisconnect = YES;
	[self refreshCurrentDevice];
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

/*- (void)addLogMessage:(NSString*)message {
	[self addLogMessage:message type:LogMessageTypeInbound];
}*/

- (void)addLogMessage:(NSString*)message type:(LogMessageType)type {
	LogMessage *logMessage = [[LogMessage alloc] initWithMessage:message type:type];
	if (message) {
		[_dataSourceLogMessages addObject:logMessage];
		NSIndexPath *targetIndexPath = [NSIndexPath indexPathForRow:_dataSourceLogMessages.count-1 inSection:0];
		[_tableViewLog insertRowsAtIndexPaths:@[targetIndexPath] withRowAnimation:UITableViewRowAnimationBottom];
		[_tableViewLog scrollToRowAtIndexPath:targetIndexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
	}
	else {
		NSLog(@"Error. Nil log message: %@", message);
	}
}

- (void)setupDevice {
	[self addLogMessage:@"Connecting to device..." type:LogMessageTypeOutbound];
	__weak typeof(self) weakself = self;
	[[TDDefaultDevice sharedDevice].selectedDevice.peripheral connectWithTimeout:kDeviceConnectTimeout completion:^(NSError *error) {
		weakself.didDisconnect = NO;
		if (!error) {
			[weakself addLogMessage:@"Connected to device" type:LogMessageTypeInbound];
			[weakself addLogMessage:@"Discovering device services..." type:LogMessageTypeOutbound];
			[[TDDefaultDevice sharedDevice].selectedDevice.peripheral discoverServicesWithCompletion:^(NSArray *services, NSError *error2) {
				if (!error2) {
					[weakself addLogMessage:@"Discovered services" type:LogMessageTypeInbound];
					LGService *uartService;
					for (LGService* service in services) {
						if ([[service.UUIDString uppercaseString] isEqualToString:uartServiceUUIDString]) {
							uartService = service;
							[weakself addLogMessage:[NSString stringWithFormat:@"Found UART service: %@", service.UUIDString] type:LogMessageTypeInbound];
							[weakself addLogMessage:@"Discovering characteristics..." type:LogMessageTypeOutbound];
							[service discoverCharacteristicsWithCompletion:^(NSArray *characteristics, NSError *error3) {
								if (!error3) {
									[weakself addLogMessage:@"Discovered characteristics" type:LogMessageTypeOutbound];
									LGCharacteristic *readCharacteristic;
									for (LGCharacteristic *characteristic in characteristics) {
										if ([[characteristic.UUIDString uppercaseString] isEqualToString:uartTXCharacteristicUUIDString]) {
											[weakself addLogMessage:[NSString stringWithFormat:@"Found TX characteristic %@", characteristic.UUIDString] type:LogMessageTypeInbound];
											readCharacteristic = characteristic;
											weakself.readCharacteristic = characteristic;
											/*CBMutableCharacteristic *noteCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:readCharacteristic.UUIDString] properties:CBCharacteristicPropertyNotify+CBCharacteristicPropertyRead
																														  value:nil permissions:CBAttributePermissionsReadable|CBAttributePermissionsWriteable];
											LGCharacteristic *characteristicForNotification = [[LGCharacteristic alloc] initWithCharacteristic:noteCharacteristic];*/
											[weakself addLogMessage:@"Subscribing for TX characteristic notifications" type:LogMessageTypeOutbound];
											[characteristic setNotifyValue:YES completion:^(NSError *error4) {
												if (!error4) {
//													[weakself addLogMessage:@"Subscribed for TX characteristic notifications" type:LogMessageTypeInbound];
												}
												else {
													[weakself addLogMessage:[NSString stringWithFormat:@"Error subscribing for TX characteristic: %@", error4] type:LogMessageTypeInbound];
												}
											} onUpdate:^(NSData *data, NSError *error5) {
												if (!error5) {
													[weakself addLogMessage:[NSString stringWithFormat:@"%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]] type:LogMessageTypeInbound];
												}
												else {
													[weakself addLogMessage:[NSString stringWithFormat:@"Error on updating TX data: %@", error5] type:LogMessageTypeInbound];
												}
											}];
										}
										else if ([[characteristic.UUIDString uppercaseString] isEqualToString:uartRXCharacteristicUUIDString]) {
											[weakself addLogMessage:[NSString stringWithFormat:@"Found RX characteristic %@", characteristic.UUIDString] type:LogMessageTypeInbound];
											weakself.writeCharacteristic = characteristic;
										}
									}
									if (!readCharacteristic) {
										[weakself addLogMessage:@"Could not find TX characteristic" type:LogMessageTypeInbound];
									}
									if (!weakself.writeCharacteristic) {
										[weakself addLogMessage:@"Could not find RX characteristic" type:LogMessageTypeInbound];
									}
									if (weakself.writeCharacteristic && weakself.dataToSend) {
										[weakself writeData:weakself.dataToSend toCharacteristic:weakself.writeCharacteristic];
										weakself.dataToSend = nil;
									}
								}
								else {
									[weakself addLogMessage:[NSString stringWithFormat:@"Error discovering device characteristics: %@", error3] type:LogMessageTypeInbound];
								}
							}];
							break;
						}
					}
					if (!uartService) {
						[weakself addLogMessage:@"Failed to found UART service" type:LogMessageTypeInbound];
					}
				}
				else {
					[weakself addLogMessage:[NSString stringWithFormat:@"Error discovering device services: %@", error2] type:LogMessageTypeInbound];
				}
			}];
		}
		else {
			[weakself addLogMessage:[NSString stringWithFormat:@"Error connecting to device: %@", error] type:LogMessageTypeInbound];
		}
	}];
}

- (void)writeData:(NSString*)data toCharacteristic:(LGCharacteristic*)characteristic {
	[self addLogMessage:[NSString stringWithFormat:@"Writing data: %@ to characteristic: %@", data, characteristic.UUIDString] type:LogMessageTypeOutbound];
	__weak typeof(self) weakself = self;
	[characteristic writeValue:[data dataUsingEncoding:NSUTF8StringEncoding] completion:^(NSError *error) {
		if (!error) {
//			[weakself addLogMessage:@"Sucessefully wrote data to write characteristic" type:LogMessageTypeInbound];
		}
		else {
			[weakself addLogMessage:[NSString stringWithFormat:@"Error writing data to characteristic: %@", error] type:LogMessageTypeInbound];
		}
	}];
}

- (void)initiateLivePlotting {
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:NSLocalizedString(@"Would you like to view this data in a graph?", nil) preferredStyle:UIAlertControllerStyleAlert];
	
	__weak typeof(self) weakself = self;
	[alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Yes", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
		[weakself performSegueWithIdentifier:@"segueLivePlot" sender:nil];
	}]];
	
	[alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"No", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
		[weakself connectAndWrite:weakself.dataToSend];
	}]];
	
	[self presentViewController:alert animated:YES completion:nil];
}

- (void)connectAndWrite:(NSString*)data {
	if (_writeCharacteristic) {
		[self writeData:_textFieldMessage.text toCharacteristic:_writeCharacteristic];
	}
	else {
		[self addLogMessage:@"Write characteristic not found. Recconnecting..." type:LogMessageTypeInbound];
		_dataToSend = _textFieldMessage.text;
		
		/**
		 *	 If there was a disconnect the device will need ot be scanned for again.
		 **/
		if (_didDisconnect) {
			[[LGCentralManager sharedInstance] scanForPeripheralsByInterval:kDeviceReconnectTimeout completion:^(NSArray *peripherals) {
				for (LGPeripheral *peripheral in peripherals) {
					if ([peripheral.UUIDString isEqualToString:[TDDefaultDevice sharedDevice].selectedDevice.peripheral.UUIDString]) {
						[TDDefaultDevice sharedDevice].selectedDevice.peripheral = peripheral;
						[self setupDevice];
						break;
					}
				}
			}];
		}
		else {
			[self setupDevice];
		}
		
	}
}

#pragma mark - Public methods

#pragma mark - Actions

- (IBAction)buttonSendMessageClicked:(UIButton *)sender {
	[_textFieldMessage resignFirstResponder];
	if ([_textFieldMessage.text isEqualToString:kLivePlotInitiateString]) {
		_dataToSend = _textFieldMessage.text;
		[self initiateLivePlotting];
	}
	else {
		[self connectAndWrite:_textFieldMessage.text];
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
	
	LogMessage *message = _dataSourceLogMessages[indexPath.row];
	
	UILabel *labelMessage = (UILabel*)[cell viewWithTag:545];
	
	labelMessage.text = message.text;
	labelMessage.textColor = message.type == LogMessageTypeOutbound ? [UIColor greenColor] : [UIColor blackColor];
	
	return cell;
}

#pragma mark - UITableViewDelegate

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
	return YES;
}

@end
