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

@interface TDCommandViewController ()

@property (nonatomic, strong) NSArray *dataSourceCommands;

@end

@implementation TDCommandViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	[self setupView];
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
		case DeviceCommandReferenceDateAndTime:
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
		textField.placeholder = placeholder;
	}];
	[self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Actions

- (IBAction)buttonBackClicked:(id)sender {
	[self.parentViewController dismissViewControllerAnimated:YES completion:nil];
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
	return CGSizeMake(([UIScreen mainScreen].bounds.size.width-60)/3, 56);
}

#pragma mark - Commands

//general
- (void)writeStringToDevice:(NSString*)string {
	__weak typeof(self) weakself = self;
	[MBProgressHUD showHUDAddedTo:self.view animated:YES];
	[LGUtils writeData:[string dataUsingEncoding:NSUTF8StringEncoding] charactUUID:CHAR_ID serviceUUID:SERVICE_ID peripheral:[TDDefaultDevice sharedDevice].selectedDevice.peripheral completion:^(NSError *error) {
		[MBProgressHUD hideAllHUDsForView:self.view animated:NO];
		if (!error) {
			UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Sucess", nil) message:nil preferredStyle:UIAlertControllerStyleAlert];
			[alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleCancel handler:nil]];
			[self presentViewController:alert animated:YES completion:nil];
		}
		else {
			UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", nil) message:[NSString stringWithFormat:NSLocalizedString(@"Error writing: %@", nil), error] preferredStyle:UIAlertControllerStyleAlert];
			[alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleCancel handler:nil]];
			[self presentViewController:alert animated:YES completion:nil];
		}
		[weakself refreshCurrentDevice];
	}];
}

- (void)changeName:(NSString*)name {
	[self writeStringToDevice:[NSString stringWithFormat:@"*nam %@", name]];
}

@end
