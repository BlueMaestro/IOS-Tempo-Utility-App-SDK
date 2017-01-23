//
//  TDCommandViewController.m
//  Tempo Utility
//
//  Created by Nikola Misic on 1/18/17.
//  Copyright © 2017 BlueMaestro. All rights reserved.
//

#import "TDCommandViewController.h"
#import "TDCommandCollectionViewCell.h"
#import <LGBluetooth/LGBluetooth.h>

#define CHAR_ID @"6E400002-B5A3-F393-E0A9-E50E24DCCA9E"
#define SERVICE_ID @"6E400001-B5A3-F393-E0A9-E50E24DCCA9E"

#define kResponseTimeout 2

typedef enum : NSInteger {
	DeviceCommandChangeName = 0,
	DeviceCommandLogginInterval,
	DeviceCommandSensorInterval,
	DeviceCommandReferenceDateAndTime,
	DeviceCommandAlarm1,
	DeviceCommandAlarm2,
	DeviceCommandClearAlarms,
	DeviceCommandAlarmOnOff,
	DeviceCommandAirplaneModeOnOff,
	DeviceCommandTransmitPower,
	DeviceCommandClearStoredData,
	DeviceCommandResetDevice,
	DeviceCommandCommandConsole
} DeviceCommand;

@interface TDCommandViewController () <UITextFieldDelegate>

@property (nonatomic, strong) NSArray *dataSourceCommands;
@property (nonatomic, weak) UITextField *textFieldCommandPopupActive;
@property (nonatomic, strong) NSDateFormatter *dateFormatterCommand;
@property (nonatomic, strong) NSTimer *timerResponseTimeout;

@end

@implementation TDCommandViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	[self setupView];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self refreshCurrentDevice];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
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
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStyleDone target:self action:@selector(buttonBackClicked:)];
	
	_dateFormatterCommand = [[NSDateFormatter alloc] init];
//	_dateFormatterCommand.locale = [NSLocale localeWithLocaleIdentifier:@"us"];
	_dateFormatterCommand.dateFormat = @"yyyy MM dd HH:mm";
	
	/**
	 *	To reorder command list just adjust this list
	 **/
	_dataSourceCommands = @[
							@(DeviceCommandChangeName),
							@(DeviceCommandLogginInterval),
							@(DeviceCommandSensorInterval),
							@(DeviceCommandReferenceDateAndTime),
							@(DeviceCommandAlarm1),
							@(DeviceCommandAlarm2),
							@(DeviceCommandClearAlarms),
							@(DeviceCommandAlarmOnOff),
							@(DeviceCommandAirplaneModeOnOff),
							@(DeviceCommandTransmitPower),
							@(DeviceCommandClearStoredData),
							@(DeviceCommandResetDevice),
							@(DeviceCommandCommandConsole)
							];
	[_collectionViewCommands reloadData];
}

- (NSString*)nameForCommand:(DeviceCommand)command {
	switch (command) {
		case DeviceCommandChangeName:
			return @"Name\nChange";
		case DeviceCommandLogginInterval:
			return @"Logging\nInterval";
		case DeviceCommandSensorInterval:
			return @"Sensor\nInterval";
		case DeviceCommandReferenceDateAndTime:
			return @"Reference\nDate & Time";
		case DeviceCommandAlarm1:
			return @"Alarm 1";
		case DeviceCommandAlarm2:
			return @"Alarm 2";
		case DeviceCommandClearAlarms:
			return @"Clear\nAlarms";
		case DeviceCommandAlarmOnOff:
			return @"Alarms\nOn/Off";
		case DeviceCommandAirplaneModeOnOff:
			return @"Airplane\nMode On/Off";
		case DeviceCommandTransmitPower:
			return @"Transmit\nPower";
		case DeviceCommandClearStoredData:
			return @"Clear\nStored Data";
		case DeviceCommandResetDevice:
			return @"Reset\nDevice";
		case DeviceCommandCommandConsole:
			return @"Command\nConsole";
	}
}

- (void)actionForCommand:(DeviceCommand)command {
	__block UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleAlert];
	UIAlertAction *action = nil;
	NSString *title = @"";//title of the alert view
	NSString *descript = @"";//description in the alert view
	NSString *placeholder = @"";//placeholder for the text field in the alert view
	__weak typeof(self) weakself = self;
	switch (command) {
		case DeviceCommandChangeName: {
			title = @"Name Change";
			descript = @"Please enter new device name";
			placeholder = @"Name here";
			action = [UIAlertAction actionWithTitle:@"Enter" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
				[weakself changeName:alert.textFields[0].text];
			}];
		}
			break;
		case DeviceCommandLogginInterval:
			break;
		case DeviceCommandSensorInterval:
			break;
		case DeviceCommandReferenceDateAndTime: {
			title = @"Reference Date & Time Change";
			descript = @"Please enter new device reference date and time";
			placeholder = @"";
			action = [UIAlertAction actionWithTitle:@"Enter" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
				NSDate *parsedDate = [weakself.dateFormatterCommand dateFromString:alert.textFields[0].text];
				if (parsedDate) {
					[weakself changeReferenceTimeAndDate:parsedDate];
				}
			}];
		}
			break;
		case DeviceCommandAlarm1:
			break;
		case DeviceCommandAlarm2:
			break;
		case DeviceCommandClearAlarms:
			break;
		case DeviceCommandAlarmOnOff:
			break;
		case DeviceCommandAirplaneModeOnOff:
			break;
		case DeviceCommandTransmitPower:
			break;
		case DeviceCommandClearStoredData:
			break;
		case DeviceCommandResetDevice:
			break;
		case DeviceCommandCommandConsole:
			break;
	}
	alert.title = title;
	alert.message = descript;
	[alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
	if (action) {
		[alert addAction:action];
	}
	
	[alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
		/**
		 *	Customize text field for the popup here
		 *	Everything that works on UITextField should work here also
		 **/
		if (command == DeviceCommandReferenceDateAndTime) {
			//customize date picker text field
			UIDatePicker *picker = [[UIDatePicker alloc] init];
			picker.datePickerMode = UIDatePickerModeDateAndTime;
			[picker addTarget:weakself action:@selector(datePickerValueChanged:) forControlEvents:UIControlEventValueChanged];
			textField.inputView = picker;
			textField.text = [_dateFormatterCommand stringFromDate:[NSDate date]];
		}

		textField.textColor = [UIColor blueMaestroBlue];
		textField.font = [UIFont fontWithName:@"Montserrat-Regular" size:textField.font.pointSize];
		textField.placeholder = placeholder;
		textField.delegate = weakself;
		weakself.textFieldCommandPopupActive = textField;
	}];
	[self presentViewController:alert animated:YES completion:nil];
}

/**
 *	Not being used, device response data (handleDeviceDataReceive:error:) will cleanup
 **/
- (void)showAlertForAction:(BOOL)success error:(NSError*)error {
	[MBProgressHUD hideAllHUDsForView:self.view animated:YES];
	if (success) {
		UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Sucess", nil) message:nil preferredStyle:UIAlertControllerStyleAlert];
		[alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleCancel handler:nil]];
		[self presentViewController:alert animated:YES completion:nil];
	}
	else {
		UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", nil) message:[NSString stringWithFormat:NSLocalizedString(@"Error writing: %@", nil), error] preferredStyle:UIAlertControllerStyleAlert];
		[alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleCancel handler:nil]];
		[self presentViewController:alert animated:YES completion:nil];
	}
}

- (void)startTimeout {
	__weak typeof (self) weakself = self;
	_timerResponseTimeout = [NSTimer timerWithTimeInterval:kResponseTimeout repeats:NO block:^(NSTimer * _Nonnull timer) {
		[weakself showAlertForAction:NO error:nil];
		[[weakself timerResponseTimeout] invalidate];
	}];
}

#pragma mark - Public methods

- (void)handleDeviceDataReceive:(NSData *)data error:(NSError *)error {
	[_timerResponseTimeout invalidate];
	NSString *message = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	
	BOOL hasWordError = [message containsString:@"error"];
	
	[MBProgressHUD hideAllHUDsForView:self.view animated:YES];
	if (!error) {
		UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Sucess", nil) message:message preferredStyle:UIAlertControllerStyleAlert];
		[alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleCancel handler:nil]];
		[self presentViewController:alert animated:YES completion:nil];
	}
	else {
		UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", nil) message:message ? message : [NSString stringWithFormat:NSLocalizedString(@"Error writing: %@", nil), error] preferredStyle:UIAlertControllerStyleAlert];
		[alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleCancel handler:nil]];
		NSLog(@"Present data receive fail");
		[self presentViewController:alert animated:YES completion:nil];
	}
}

- (void)handleDisconnectNotification:(NSNotification *)note {
	if ([MBProgressHUD allHUDsForView:self.view].count > 0 && !_timerResponseTimeout) {
		[MBProgressHUD hideAllHUDsForView:self.view animated:NO];
		UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", nil) message:[NSString stringWithFormat:NSLocalizedString(@"There was an error writing data.", nil)] preferredStyle:UIAlertControllerStyleAlert];
		[alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleCancel handler:nil]];
		NSLog(@"Present disconnect");
		[self presentViewController:alert animated:YES completion:nil];
	}
	[super handleDisconnectNotification:note];
}

#pragma mark - Actions

- (IBAction)buttonBackClicked:(id)sender {
	[self.parentViewController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)datePickerValueChanged:(UIDatePicker*)sender {
	_textFieldCommandPopupActive.text = [_dateFormatterCommand stringFromDate:sender.date];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
	return _dataSourceCommands.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	TDCommandCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cellCommand" forIndexPath:indexPath];
	
	DeviceCommand command = [_dataSourceCommands[indexPath.row] integerValue];
	cell.labelCommandName.text = [self nameForCommand:command];
	
	return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
	DeviceCommand command = [_dataSourceCommands[indexPath.row] integerValue];
	/**
	 *	If there is a custom action which should not implement the standard alert then override here instead of calling actionForCommand:
	 **/
	if (command == DeviceCommandCommandConsole) {
		[self performSegueWithIdentifier:@"segueShowUART" sender:nil];
	}
	else {
		[self actionForCommand:command];
	}
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
	return CGSizeMake(([UIScreen mainScreen].bounds.size.width-60)/3, 60);
}

#pragma mark - UITextFieldDelegate

#pragma mark - Commands

- (void)changeName:(NSString*)name {
	/**
	 *	This would be the base for any command
	 *	Every command should at least have this code with maybe some data parse or validation
	 *	weakself is for memory management (strong reference cycles) so our callback blocks dont retain the controller
	 *	MBProgressHUD is to block the UI until the action is complete
	 *	showAlertForAction:error: shows the alert that reports if the action was a success and does the cleanup (e.g. removes the MBProgressHUD)
	 **/
	__weak typeof(self) weakself = self;
	[MBProgressHUD showHUDAddedTo:self.view animated:YES];
	[self connectAndWrite:[NSString stringWithFormat:@"*nam %@", name] withCompletion:^(BOOL success, NSError *error) {
		[weakself startTimeout];
	}];
}

- (void)changeReferenceTimeAndDate:(NSDate*)targetDate {
	NSCalendar *calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
	unsigned unitFlags = (NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute);
	NSDateComponents *components = [calendar components:unitFlags fromDate:targetDate];
	//yyMMddHHmm
	NSInteger number = components.minute + components.hour*100 + components.day*10000 + components.month*1000000 + (components.year%100)*100000000;
	
	__weak typeof(self) weakself = self;
	[MBProgressHUD showHUDAddedTo:self.view animated:YES];
	[self connectAndWrite:[NSString stringWithFormat:@"*d %ld", number] withCompletion:^(BOOL success, NSError *error) {
		[weakself startTimeout];
	}];
}

@end
