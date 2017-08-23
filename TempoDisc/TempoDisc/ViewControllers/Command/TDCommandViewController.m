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

#define kResponseTimeout 30

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
    DeviceCommandUnits,
    DeviceCommandLock,
    DeviceCalibrateTemperature,
    DeviceCalibrateHumidity,
    DeviceDisableButton,
    DeviceSetDeviceID,
    DeviceSetTransmissionInterval,
    DeviceFirmwareUpgrade,
    DeviceAltitude,
	DeviceCommandCommandConsole
} DeviceCommand;

typedef enum : NSInteger {
    ThresholdAbove = 0,
    ThresholdBelow,
} ThresholdForAlarm;


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
    NSLog(@"Version being passed through is %i", (int)self.versionNumber);
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
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(buttonBackClicked:)];
	
	_dateFormatterCommand = [[NSDateFormatter alloc] init];
//	_dateFormatterCommand.locale = [NSLocale localeWithLocaleIdentifier:@"us"];
	_dateFormatterCommand.dateFormat = @"yyyy MM dd HH:mm";
	
	/**
	 *	To reorder command list just adjust this list
	 **/
    
    if ((int)self.versionNumber == 13) {
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
                                @(DeviceCommandUnits),
                                @(DeviceCommandLock),
                                @(DeviceCalibrateTemperature),
                                @(DeviceDisableButton),
                                @(DeviceSetDeviceID),
                                @(DeviceSetTransmissionInterval),
                                @(DeviceCommandCommandConsole)
                                ];
        [_collectionViewCommands reloadData];
    }
    if ((int)self.versionNumber == 23) {
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
                            @(DeviceCommandUnits),
                            @(DeviceCommandLock),
                            @(DeviceCalibrateTemperature),
                            @(DeviceCalibrateHumidity),
                            @(DeviceDisableButton),
                            @(DeviceSetDeviceID),
                            @(DeviceSetTransmissionInterval),
							@(DeviceCommandCommandConsole)
							];
	[_collectionViewCommands reloadData];
    }
    
    
    if (((int)self.versionNumber != 23) && ((int)self.versionNumber != 13)  && ((int)self.versionNumber != 27) && ((int)self.versionNumber !=52))  {
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
                                @(DeviceCommandUnits),
                                @(DeviceCommandLock),
                                @(DeviceCommandCommandConsole)
                                ];
        [_collectionViewCommands reloadData];
    }
    
    if ((int)self.versionNumber == 27) {
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
                                @(DeviceCommandUnits),
                                @(DeviceCommandLock),
                                @(DeviceCalibrateTemperature),
                                @(DeviceCalibrateHumidity),
                                @(DeviceDisableButton),
                                @(DeviceSetDeviceID),
                                @(DeviceSetTransmissionInterval),
                                @(DeviceAltitude),
                                @(DeviceCommandCommandConsole)
                                ];
    [_collectionViewCommands reloadData];
    }
    
    if ((int)self.versionNumber == 52) {
        _dataSourceCommands = @[
                                @(DeviceCommandChangeName),
                                @(DeviceCommandLogginInterval),
                                @(DeviceCommandReferenceDateAndTime),
                                @(DeviceCommandAirplaneModeOnOff),
                                @(DeviceCommandTransmitPower),
                                @(DeviceCommandClearStoredData),
                                @(DeviceCommandResetDevice),
                                @(DeviceCommandLock),
                                @(DeviceCommandCommandConsole)
                                ];
        [_collectionViewCommands reloadData];
    }
    
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
			return @"Alarm 1\nSet";
		case DeviceCommandAlarm2:
			return @"Alarm 2\nSet";
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
        case DeviceCommandUnits:
            return @"Change\n ºC / ºF";
        case DeviceCommandLock:
            return@"Lock/Unlock\nDevice";
        case DeviceCalibrateHumidity:
            return@"Calibrate\nHumidity";
        case DeviceCalibrateTemperature:
            return@"Calibrate\nTemperature";
        case DeviceDisableButton:
            return@"Disable\nButton";
        case DeviceSetDeviceID:
            return@"Set Device\nClass ID";
        case DeviceSetTransmissionInterval:
            return@"Set Advertising\nFrequency";
        case DeviceFirmwareUpgrade:
            return@"Firmware\nUpgrade";
        case DeviceAltitude:
            return@"Set Altitude";
		case DeviceCommandCommandConsole:
			return @"Command\nConsole";
	}
}

- (void)actionForCommand:(DeviceCommand)command {
	__block UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleAlert];
    __block UIAlertController *alert_input_issue = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleAlert];
	UIAlertAction *actionOne = nil;
    UIAlertAction *actionTwo = nil;
    UIAlertAction *actionThree = nil;
    UIAlertAction *actionFour = nil;
    bool presentInputBox = 0;
    bool inputNumeralOnly = 0;
	NSString *title = @"";//title of the alert view
	NSString *descript = @"";//description in the alert view
	NSString *placeholder = @"";//placeholder for the text field in the alert view
	__weak typeof(self) weakself = self;
	switch (command) {
        
		case DeviceCommandChangeName:
        {
			title = @"Name Change";
			descript = @"Please enter new device name.\nThis cannot be more than 8 characters long and any name longer will be shortened.";
			placeholder = @"Enter new name";
			actionOne = [UIAlertAction actionWithTitle:@"Change" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
				[weakself changeName:alert.textFields[0].text];
			}];
            presentInputBox = true;
            break;
		}
			

            
        case DeviceCommandLogginInterval:
        {
            title = @"Logging Interval";
            descript = @"Please enter logging interval in seconds.  The default is 3,600 seconds (1 hour).  Please enter a value between 2 and 86,400 (24 hours).  WARNING:  Changing this interval will result in stored data being cleared in the device.";
            actionOne = [UIAlertAction actionWithTitle:@"Set" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                int value = [alert.textFields[0].text intValue];
                if ((value < 2) || (value > 86400)) {
                    alert_input_issue.title = @"Invalid Parameter";
                    alert_input_issue.message = @"The value entered appears to be outside the required parameters.  Please check and try again.";
                    [alert_input_issue addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
                    [self presentViewController:alert_input_issue animated:YES completion:nil];
                    
                } else {
                [weakself changeLoggingInterval:value];
                }
            }];
            presentInputBox = true;
            inputNumeralOnly = true;
            break;
        }
			
            
        case DeviceCommandSensorInterval:
        {
            title = @"Sensor Interval";
            descript = @"Please enter sensor interval in seconds.  This is the rate at which the sensors are polled and current values are updated.  It does not affect the logging interval.  The default is 10 seconds.  Please enter a value between 2 and 86,400 (24 hours).";
            actionOne = [UIAlertAction actionWithTitle:@"Enter" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                int value = [alert.textFields[0].text intValue];
                if ((value < 2) || (value > 86400)) {
                    alert_input_issue.title = @"Invalid Parameter";
                    alert_input_issue.message = @"The value entered appears to be outside the required parameters.  Please check and try again.";
                    [alert_input_issue addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
                    [self presentViewController:alert_input_issue animated:YES completion:nil];
                    
                } else {
                [weakself changeSensorInterval:value];
                }
            }];
            presentInputBox = true;
            inputNumeralOnly = true;
            break;
        }
			
            
            
		case DeviceCommandReferenceDateAndTime:
        {
			title = @"Reference Date & Time";
			descript = @"Please enter a reference date and time for logging purposes.  This should be when the device was first turned on or reset since the first log is recorded straight away.  Each subsequent log timestamp will refer back to this.  WARNING:  Changing this will result in stored data being cleared in the device.";
			placeholder = @"";
			actionOne = [UIAlertAction actionWithTitle:@"Change" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
				NSDate *parsedDate = [weakself.dateFormatterCommand dateFromString:alert.textFields[0].text];
				if (parsedDate) {
					[weakself changeReferenceTimeAndDate:parsedDate];
				}
			}];
            presentInputBox = true;
            break;
        }
			
            
            
		case DeviceCommandAlarm1:
        {
            title = @"Set Alarm 1";
            descript = @"Enter a value and and then select an alarm parameter.  For example Temperature < 10 means each time temperature is below 10, this will be logged and an alert will be raised when scanning the device.  Enter only whole numbers for the relavant units of measure.";
            placeholder = @"";
            NSString *temperature = [NSString stringWithFormat:@"t"];
            NSString *humidity = [NSString stringWithFormat:@"h"];
            NSString *symbolGreater = [NSString stringWithFormat:@">"];
            NSString *symbolLesser = [NSString stringWithFormat:@"<"];
            
            actionOne = [UIAlertAction actionWithTitle:@"Temperature < Value" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                NSString *command = alert.textFields[0].text;
                int roundValue = [command intValue];
                NSString *valueToSet = [NSString stringWithFormat:@"%d", roundValue];
                NSLog(@"Entered value is %@ and rounded value is %d", command, roundValue);
                [weakself setAlarm:1 valueToSet:valueToSet whetherHumiOrTemp:temperature withThreshold:symbolLesser];
                
            }];
            actionTwo = [UIAlertAction actionWithTitle:@"Temperature > Value" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                NSString *command = alert.textFields[0].text;
                int roundValue = [command intValue];
                NSString *valueToSet = [NSString stringWithFormat:@"%d", roundValue];
                NSLog(@"Entered value is %@ and rounded value is %d", command, roundValue);
                [weakself setAlarm:1 valueToSet:valueToSet whetherHumiOrTemp:temperature withThreshold:symbolGreater];
            }];
            actionThree = [UIAlertAction actionWithTitle:@"Humidity < Value" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                NSString *command = alert.textFields[0].text;
                int roundValue = [command intValue];
                NSString *valueToSet = [NSString stringWithFormat:@"%d", roundValue];
                NSLog(@"Entered value is %@ and rounded value is %d", command, roundValue);
                [weakself setAlarm:1 valueToSet:valueToSet whetherHumiOrTemp:humidity withThreshold:symbolLesser];
            }];
            actionFour = [UIAlertAction actionWithTitle:@"Humidity > Value" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                NSString *command = alert.textFields[0].text;
                int roundValue = [command intValue];
                NSString *valueToSet = [NSString stringWithFormat:@"%d", roundValue];
                NSLog(@"Entered value is %@ and rounded value is %d", command, roundValue);
                [weakself setAlarm:1 valueToSet:valueToSet whetherHumiOrTemp:humidity withThreshold:symbolGreater];
            }];
            presentInputBox = true;
            inputNumeralOnly = true;
            break;
            
        }
			
            
            
		case DeviceCommandAlarm2:
        {
            title = @"Set Alarm 2";
            descript = @"Enter a value and and then select an alarm parameter.  For example Temperature < 10 means each time temperature is below 10, this will be logged and an alert will be raised when scanning the device.  Enter only whole numbers for the relavant units of measure.";
            placeholder = @"";
            NSString *temperature = [NSString stringWithFormat:@"t"];
            NSString *humidity = [NSString stringWithFormat:@"h"];
            NSString *symbolGreater = [NSString stringWithFormat:@">"];
            NSString *symbolLesser = [NSString stringWithFormat:@"<"];
            actionOne = [UIAlertAction actionWithTitle:@"Temperature < Value" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                NSString *command = alert.textFields[0].text;
                int roundValue = [command intValue];
                NSString *valueToSet = [NSString stringWithFormat:@"%d", roundValue];
                NSLog(@"Entered value is %@ and rounded value is %d", command, roundValue);
                [weakself setAlarm:2 valueToSet:valueToSet whetherHumiOrTemp:temperature withThreshold:symbolLesser];
                
            }];
            actionTwo = [UIAlertAction actionWithTitle:@"Temperature > Value" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                NSString *command = alert.textFields[0].text;
                int roundValue = [command intValue];
                NSString *valueToSet = [NSString stringWithFormat:@"%d", roundValue];
                NSLog(@"Entered value is %@ and rounded value is %d", command, roundValue);
                [weakself setAlarm:2 valueToSet:valueToSet whetherHumiOrTemp:temperature withThreshold:symbolGreater];
            }];
            actionThree = [UIAlertAction actionWithTitle:@"Humidity < Value" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                NSString *command = alert.textFields[0].text;
                int roundValue = [command intValue];
                NSString *valueToSet = [NSString stringWithFormat:@"%d", roundValue];
                NSLog(@"Entered value is %@ and rounded value is %d", command, roundValue);
                [weakself setAlarm:2 valueToSet:valueToSet whetherHumiOrTemp:humidity withThreshold:symbolLesser];
            }];
            actionFour = [UIAlertAction actionWithTitle:@"Humidity > Value" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                NSString *command = alert.textFields[0].text;
                int roundValue = [command intValue];
                NSString *valueToSet = [NSString stringWithFormat:@"%d", roundValue];
                NSLog(@"Entered value is %@ and rounded value is %d", command, roundValue);
                [weakself setAlarm:2 valueToSet:valueToSet whetherHumiOrTemp:humidity withThreshold:symbolGreater];
            }];
            presentInputBox = true;
            inputNumeralOnly = true;
            break;
        }
		
          
            
		case DeviceCommandClearAlarms:
        {
            title = @"Clear Alarms";
            descript = @"This clears the alarms by reseting the alarm counter, but does not change any parameters.";
            placeholder = @"";
            actionOne = [UIAlertAction actionWithTitle:@"Confirm" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    [weakself clearAlarms];
            }];
            break;
        }
			
            
            
		case DeviceCommandAlarmOnOff:
        {
            title = @"Turn Alarms Off";
            descript = @"If any of the alarms are set you can turn them off here.  This will not reset the alarm counter, but to turn them back on you will need to set them again.";
            placeholder = @"";
            actionOne = [UIAlertAction actionWithTitle:@"Turn Alarm 1 Off" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [weakself alarmOnOff:1];
            }];
            actionTwo = [UIAlertAction actionWithTitle:@"Turn Alarm 2 Off" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [weakself alarmOnOff:0];
            }];
            break;
        }
			
            
            
		case DeviceCommandAirplaneModeOnOff:
        {
            title = @"Turn Airplane Mode On / Off";
            descript = @"Airplane mode means the device will stop radio transmission after 5 minutes.  It continues to log data.  Transmission can be reactivated for another 5 minutes by pushing the button.";
            placeholder = @"";
            actionOne = [UIAlertAction actionWithTitle:@"Airplane Mode On" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    [weakself turnAirplaneMode:1];
            }];
            actionTwo = [UIAlertAction actionWithTitle:@"Airplane Mode Off" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    [weakself turnAirplaneMode:0];
            }];
            break;
            
        }
			
            
            
		case DeviceCommandTransmitPower:
        {
            title = @"Set transmission power";
            descript = @"Select the transmission power of the device.  Lowering the transmission increases battery life but may affect transmission range";
            placeholder = @"";
            actionOne = [UIAlertAction actionWithTitle:@"+4dB (strongest & default)" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [weakself setTransmissionPower:0];
            }];
            actionTwo = [UIAlertAction actionWithTitle:@"0dB" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [weakself setTransmissionPower:1];
            }];
            actionThree = [UIAlertAction actionWithTitle:@"-4dB (weakest)" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [weakself setTransmissionPower:2];
            }];
            break;
        }
			
            
            
		case DeviceCommandClearStoredData:
        {
            title = @"Clear Stored Data";
            descript = @"Clears the stored data and the reference date but leaves other settings such as name, units and logging interval unchanged.";
            placeholder = @"";
            actionOne = [UIAlertAction actionWithTitle:@"Confirm" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    [weakself clearStoredData];
                
            }];
            break;
        }
            
			
            
            
		case DeviceCommandResetDevice:
        {
            title = @"Reset the Device";
            descript = @"Resets the device back to factory settings.  All data and settings are erased.";
            placeholder = @"";
            actionOne = [UIAlertAction actionWithTitle:@"Confirm" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    [weakself rebootDevice];
            
            }];
           
            break;
        }
            
			
            
            
        case DeviceCommandUnits:
        {
            title = @"Set Units";
            descript = @"Set the units of measure for temperature.  The default is º Celsius";
            placeholder = @"";
            actionOne = [UIAlertAction actionWithTitle:@"º Fahrenheit" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
                [weakself changeUnits:0];
                
            }];
            actionTwo = [UIAlertAction actionWithTitle:@"º Celsius" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [weakself changeUnits:1];
                
            }];
            break;
            
        }
            
            
            
        case DeviceCommandLock:
        {
            title = @"Lock / Unlock the Device";
            descript = @"Enter a 4 digit pin to prevent settings being changed by locking the device.  If the pin is forgotten, removing the battery will reset it.  Re-enter the same pin to unlock the device";
            placeholder = @"";
            actionOne = [UIAlertAction actionWithTitle:@"Lock/Unlock" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                NSString *password = alert.textFields[0].text;
                [weakself setPassword:password];
            }];
            presentInputBox = true;
            inputNumeralOnly = true;
            break;
            
        }
            
            
        case DeviceCalibrateHumidity:
        {
            title = @"Calibrate Humidity";
            descript = @"Enter the calibration offset for humidity.  This will apply to logged values going forward and does not affect existing logged values.";
            placeholder = @"";
            actionOne = [UIAlertAction actionWithTitle:@"Enter" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                NSString *enteredValue = alert.textFields[0].text;
                [weakself calibrateHumidity:enteredValue];
            }];
            presentInputBox = true;
            inputNumeralOnly = true;
            break;
            
        }
            
            
    
        case DeviceCalibrateTemperature:
        {
            title = @"Calibrate Temperature";
            descript = @"Enter the calibration offset for temperature.  This will apply to logged values going forward and does not affect existing logged values.  Enter a value applicable to the current units of measure set for the device.";
            placeholder = @"";
            actionOne = [UIAlertAction actionWithTitle:@"Enter" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                NSString *enteredValue = alert.textFields[0].text;
                [weakself calibrateTemperature:enteredValue];
            }];
            presentInputBox = true;
            inputNumeralOnly = true;
            break;
            
        }
            
            
            
            
        case DeviceDisableButton:
        {
            title = @"Disable Button";
            descript = @"This command disables the button to prevent it turning the device off.  Pressing it will still cause the device's LED to blink and cause the device to advertise if it is in airplane mode.";
            placeholder = @"";
            actionOne = [UIAlertAction actionWithTitle:@"Toggle On/Off" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [weakself toggleButton];
            }];
            break;
        }
            
            
            
        case DeviceSetDeviceID:
        {
            
            title = @"Set Device Class ID";
            descript = @"Enter a number between 1 - 254 that will be an additional identifier for the device.  This function is ideal if you want to organise devices into groups (based on location, for example) where the name alone is not sufficient to identify the device.";
            placeholder = @"";
            actionOne = [UIAlertAction actionWithTitle:@"Set ID" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                NSString *enteredValue = alert.textFields[0].text;
                [weakself setDeviceID:enteredValue];
                
            }];
            presentInputBox = true;
            inputNumeralOnly = true;
            break;
        }
            
            
            
        case DeviceSetTransmissionInterval:
        {
            title = @"Transmission Fequency";
            descript = @"Choose a transmission (or advertising) frequency to prolong battery life.  A higher setting means less frequent transmissions and increased battery life.  Note, on a button push or finishing a connection, the device is always fast for 3 minutes.";
            placeholder = @"";
            actionOne = [UIAlertAction actionWithTitle:@"100ms" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [weakself setAdvertisingSpeed:100];
                
            }];
            actionTwo = [UIAlertAction actionWithTitle:@"300ms" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [weakself setAdvertisingSpeed:300];
                
            }];
            actionThree = [UIAlertAction actionWithTitle:@"600ms (Default)" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [weakself setAdvertisingSpeed:600];
                
            }];
            actionFour = [UIAlertAction actionWithTitle:@"1000ms" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [weakself setAdvertisingSpeed:1000];
                
            }];
            break;
            
        }
    
        case DeviceFirmwareUpgrade:
        {
            title = @"Firmware Upgrade";
            descript = @"This puts the device into DFU mode ready to accept a firmware upgrade.  The device will advertise itself as 'DFU Targ' and will no longer be visible in this app until the firmware is upgraded.  For further instructions please refer to www.bluemaestro.com";
            placeholder = @"";
            actionOne = [UIAlertAction actionWithTitle:@"Upgrade" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [weakself enterDFU];
            }];
            break;
        }
            
        case DeviceAltitude:
        {
            title = @"Set Altitude";
            descript = @"Set your current altitude to get a sea level adjusted pressure reading (as used in weather forecasts).  Enter altitude in meters above sea level.";
            placeholder = @"";
            actionOne = [UIAlertAction actionWithTitle:@"Set Altitude" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                NSString *enteredValue = alert.textFields[0].text;
                [weakself setAltitude:enteredValue];
                
            }];
            presentInputBox = true;
            inputNumeralOnly = true;
            break;
        }
            
            
            break;
		case DeviceCommandCommandConsole:
			break;
	}
	alert.title = title;
	alert.message = descript;
	[alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
	if (actionOne) {
		[alert addAction:actionOne];
	}
    if (actionTwo) {
        [alert addAction:actionTwo];
    }
    if (actionThree) {
        [alert addAction:actionThree];
    }
    if (actionFour) {
        [alert addAction:actionFour];
    }
    if (presentInputBox){
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
            if (inputNumeralOnly) {
        textField.keyboardType = UIKeyboardTypeNumberPad;
            }
		textField.textColor = [UIColor blueMaestroBlue];
		textField.font = [UIFont fontWithName:@"Montserrat-Regular" size:textField.font.pointSize];
		textField.placeholder = placeholder;
		textField.delegate = weakself;
		weakself.textFieldCommandPopupActive = textField;
        }];
    }
	[self presentViewController:alert animated:YES completion:nil];
}


/**
 *	Not being used, device response data (handleDeviceDataReceive:error:) will cleanup
 **/
- (void)showAlertForAction:(BOOL)success error:(NSError*)error {
	[MBProgressHUD hideAllHUDsForView:self.view animated:YES];
	if (success) {
		UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Success", nil) message:nil preferredStyle:UIAlertControllerStyleAlert];
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
	
	[[NSRunLoop mainRunLoop] addTimer:_timerResponseTimeout forMode:NSDefaultRunLoopMode];
}

- (NSString*)manipulateString:(NSString*)target {
	/**
	 *	Do some manipulation
	 **/
	
	
	return target;
	
	/**
	 *	If this method is used in more UIViewControllers then its better to move it to TDHelper class so it can be called everywhere with:
	 *	[TDHepler manipulateString:string]
	 *	Just use "+" instead of "-" at the start to make it class method instead of instance method
	 **/
}

#pragma mark - Public methods

- (void)handleDeviceDataReceive:(NSData *)data error:(NSError *)error {
	[_timerResponseTimeout invalidate];
	NSString *message = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	
	BOOL hasWordError = [message containsString:@"error"];
	
	//if we need the position of the "error" string
	NSRange rangeOfError = [message rangeOfString:@"error"];
	if (rangeOfError.location != NSNotFound) {
		/**
		 *	exists
		 *	rangeOfError.location is the location of the "e" character
		 *	rangeOfError.length is the length of the "error" string
		**/
		
		//to get the rest of the string after "error" we can use
		NSString *restOfMessage = [message substringFromIndex:rangeOfError.location+rangeOfError.length];
		
		//or before
		NSString *beforeErrorString = [message substringToIndex:rangeOfError.location];
		
		//to remove the "error" from the message we can use
		NSString *messageWithoutError = [message stringByReplacingOccurrencesOfString:@"error" withString:@""];
		
		//finally this method can be adjusted to manipulate the string for the desired effect
		NSString *endResult = [self manipulateString:message];
	}
	
	[MBProgressHUD hideAllHUDsForView:self.view animated:YES];
	if (!error) {
		UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Success", nil) message:[NSString stringWithFormat:@"Device Response:\n%@", message] preferredStyle:UIAlertControllerStyleAlert];
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

- (void)connectAndWrite:(NSString *)data withCompletion:(WriteCompletion)completion {
	[self startTimeout];
	self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
	[self.hud setLabelText:@"Connecting..."];
	[super connectAndWrite:data withCompletion:completion];
}

#pragma mark - Actions

- (IBAction)buttonBackClicked:(id)sender {
	[self.navigationController popViewControllerAnimated:YES];
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
	[self connectAndWrite:[NSString stringWithFormat:@"*nam%@", name] withCompletion:^(BOOL success, NSError *error) {
//		[weakself showAlertForAction:success error:error];
	}];
    
    
    
}

- (void)changeReferenceTimeAndDate:(NSDate*)targetDate {
    __block UIAlertController *alert_input_issue = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleAlert];
	NSCalendar *calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
	unsigned unitFlags = (NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute);
	NSDateComponents *components = [calendar components:unitFlags fromDate:targetDate];
	NSInteger number = components.minute + components.hour*100 + components.day*10000 + components.month*1000000 + (components.year-2000)*100000000;
    NSLog(@"The number for the date is %ld", (long)number);
    if (((long)number < 1700000000) || ((long)number > 1800000000)) {
        alert_input_issue.title = @"Invalid Parameter";
        alert_input_issue.message = @"The value entered appears to be outside the required parameters.  Please check and try again.";
        [alert_input_issue addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:alert_input_issue animated:YES completion:nil];
        
    } else {
        __weak typeof(self) weakself = self;
        [self connectAndWrite:[NSString stringWithFormat:@"*d%ld", (long)number] withCompletion:^(BOOL success, NSError *error) {
//		[weakself showAlertForAction:success error:error];
        }];
    }
}

-(void)changeLoggingInterval:(NSInteger)seconds {
    __weak typeof(self) weakself = self;
    NSLog(@"The seconds coming through are %d", seconds);
    [self connectAndWrite:[NSString stringWithFormat:@"*lint%ld", (long)seconds] withCompletion:^(BOOL success, NSError *error) {
//        [weakself showAlertForAction:success error:error];
    }];
}

-(void)changeSensorInterval:(NSInteger)seconds {
    __weak typeof(self) weakself = self;
    [self connectAndWrite:[NSString stringWithFormat:@"*sint%ld", (long)seconds] withCompletion:^(BOOL success, NSError *error) {
//        [weakself showAlertForAction:success error:error];
    }];
}

-(void)changeUnits:(NSInteger)which {
    //if which==1 then change to celsius if which !=1 then change to fahrenheit
    __weak typeof(self) weakself = self;
    if (which == 1) {
        [self connectAndWrite:[NSString stringWithFormat:@"*unitsc"] withCompletion:^(BOOL success, NSError *error) {
//        [weakself showAlertForAction:success error:error];
        }];
    } else {
        [self connectAndWrite:[NSString stringWithFormat:@"*unitsf"] withCompletion:^(BOOL success, NSError *error) {
//        [weakself showAlertForAction:success error:error];
        }];
    }
    
}

-(void)turnAirplaneMode:(int)which {
    //if which==1 then change then turn airplane on if which 0 then turn airplane off
    __weak typeof(self) weakself = self;
    if (which == 1) {
        [self connectAndWrite:[NSString stringWithFormat:@"*airon"] withCompletion:^(BOOL success, NSError *error) {
//            [weakself showAlertForAction:success error:error];
        }];
    } else {
        [self connectAndWrite:[NSString stringWithFormat:@"*airoff"] withCompletion:^(BOOL success, NSError *error) {
//            [weakself showAlertForAction:success error:error];
        }];
    }
}

-(void)setTransmissionPower:(int)level {
    __weak typeof(self) weakself = self;
    NSString* command = [NSString stringWithFormat:@"*txp%d", level];
    [self connectAndWrite:command withCompletion:^(BOOL success, NSError *error) {
//        [weakself showAlertForAction:success error:error];
    }];
}



-(void)alarmOnOff:(int)which {
    //if which==1 then change then turn alarm 2 off if which 0 then turn alarm 1 off
    __weak typeof(self) weakself = self;
    if (which == 1) {
        [self connectAndWrite:[NSString stringWithFormat:@"*alrm2t-"] withCompletion:^(BOOL success, NSError *error) {
//            [weakself showAlertForAction:success error:error];
        }];
    } else {
        [self connectAndWrite:[NSString stringWithFormat:@"*alrm1t-"] withCompletion:^(BOOL success, NSError *error) {
//            [weakself showAlertForAction:success error:error];
        }];
    }
}


-(void)setAlarm:(int)alarmNumber valueToSet:(NSString *)alarmValue whetherHumiOrTemp:(NSString *)whichMetric withThreshold:(NSString *)threshold {
    __weak typeof(self) weakself = self;
    NSString *alarmNumberIntoString = [NSString stringWithFormat:@"%d", alarmNumber];
    NSString *commandPrefix = @("*alrm");
    NSString *symbol;
    if (threshold == ThresholdBelow) {
        symbol = @"<";
    } else {
        symbol = @">";
    }
    NSString *concenatedComand = [NSString stringWithFormat:@"%@%@%@%@%@", commandPrefix, alarmNumberIntoString, whichMetric, threshold, alarmValue];
    NSLog(@"Alarm concenated command is %@", concenatedComand);
   
    [self connectAndWrite:concenatedComand withCompletion:^(BOOL success, NSError *error) {
//        [weakself showAlertForAction:success error:error];
		
    }];
}


-(void)clearAlarms{
    __weak typeof(self) weakself = self;
    [self connectAndWrite:[NSString stringWithFormat:@"*alrmclr"] withCompletion:^(BOOL success, NSError *error) {
//        [weakself showAlertForAction:success error:error];
    }];
}


-(void)clearStoredData {
    __weak typeof(self) weakself = self;
        [self connectAndWrite:[NSString stringWithFormat:@"*clr"] withCompletion:^(BOOL success, NSError *error) {
//            [weakself showAlertForAction:success error:error];
        }];
}


-(void)rebootDevice{

    __weak typeof(self) weakself = self;
        [self connectAndWrite:[NSString stringWithFormat:@"*rboot"] withCompletion:^(BOOL success, NSError *error) {
//            [weakself showAlertForAction:success error:error];
        }];
}

-(void)setPassword:(NSString *)password{
    __weak typeof(self) weakself = self;
     __block UIAlertController *alert_input_issue = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleAlert];
    int checkNumber = [password intValue];
    NSNumberFormatter *checkIsNumeric = [[NSNumberFormatter alloc] init];
    BOOL isDecimal = [checkIsNumeric numberFromString:password];
    NSLog(@"Password numeric %d and number is %d", isDecimal, checkNumber);
    if ((checkNumber > 9999) || (checkNumber < 0) || (!isDecimal)) {
        alert_input_issue.title = @"Invalid Pin";
        alert_input_issue.message = @"The value entered appears to be outside the required parameters.  Please check and try again.";
        [alert_input_issue addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:alert_input_issue animated:YES completion:nil];
    } else {
        NSString *command = [NSString stringWithFormat:@"*pwd%@", password];
        
        [self connectAndWrite:command withCompletion:^(BOOL success, NSError *error) {
//            [weakself showAlertForAction:success error:error];
        }];
        
    }
    
}

-(void)calibrateHumidity:(NSString *)newValue {
    __weak typeof(self) weakself = self;
    __block UIAlertController *alert_input_issue = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleAlert];
    NSNumberFormatter *checkIsNumeric = [[NSNumberFormatter alloc] init];
    BOOL isDecimal = [checkIsNumeric numberFromString:newValue];
    if (!isDecimal) {
        alert_input_issue.title = @"Invalid Entry";
        alert_input_issue.message = @"The value entered appears to be outside the required parameters.  Please check and try again.";
        [alert_input_issue addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:alert_input_issue animated:YES completion:nil];
    } else {
        NSString *command = [NSString stringWithFormat:@"*ch%@", newValue];
        
        [self connectAndWrite:command withCompletion:^(BOOL success, NSError *error) {
//            [weakself showAlertForAction:success error:error];
        }];

    }
}

-(void)calibrateTemperature:(NSString *)newValue {
    __weak typeof(self) weakself = self;
    __block UIAlertController *alert_input_issue = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleAlert];
    NSNumberFormatter *checkIsNumeric = [[NSNumberFormatter alloc] init];
    BOOL isDecimal = [checkIsNumeric numberFromString:newValue];
    if (!isDecimal) {
        alert_input_issue.title = @"Invalid Entry";
        alert_input_issue.message = @"The value entered appears to be outside the required parameters.  Please check and try again.";
        [alert_input_issue addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:alert_input_issue animated:YES completion:nil];
    } else {
        NSString *command = [NSString stringWithFormat:@"*ct%@", newValue];
        
        [self connectAndWrite:command withCompletion:^(BOOL success, NSError *error) {
//            [weakself showAlertForAction:success error:error];
			
        }];
    }
}

-(void)toggleButton{
    __weak typeof(self) weakself = self;
    [self connectAndWrite:[NSString stringWithFormat:@"*bd"] withCompletion:^(BOOL success, NSError *error) {
//        [weakself showAlertForAction:success error:error];
    }];
    
}

-(void)setDeviceID:(NSString *)enteredValue {
    __weak typeof(self) weakself = self;
    [self connectAndWrite:[NSString stringWithFormat:@"*id%@",enteredValue] withCompletion:^(BOOL success, NSError *error) {
//        [weakself showAlertForAction:success error:error];
    }];
}

-(void)setAltitude:(NSString *)enteredValue {
    __weak typeof(self) weakself = self;
    [self connectAndWrite:[NSString stringWithFormat:@"*alt%@",enteredValue] withCompletion:^(BOOL success, NSError *error) {
        //        [weakself showAlertForAction:success error:error];
    }];
}




-(void)setAdvertisingSpeed:(int)speed {
    __weak typeof(self) weakself = self;
    switch (speed)
    {
        case 100:
        {
            [self connectAndWrite:[NSString stringWithFormat:@"*sadv100"] withCompletion:^(BOOL success, NSError *error) {
//                [weakself showAlertForAction:success error:error];
            }];
            break;
        }
        case 300:
        {
            [self connectAndWrite:[NSString stringWithFormat:@"*sadv300"] withCompletion:^(BOOL success, NSError *error) {
//                [weakself showAlertForAction:success error:error];
            }];
            break;
        }
        case 600:
        {
            [self connectAndWrite:[NSString stringWithFormat:@"*sadv600"] withCompletion:^(BOOL success, NSError *error) {
//                [weakself showAlertForAction:success error:error];
            }];
            break;
        }
        case 1000:
        {
            [self connectAndWrite:[NSString stringWithFormat:@"*sadv1000"] withCompletion:^(BOOL success, NSError *error) {
//                [weakself showAlertForAction:success error:error];
            }];
            break;
        }
            default:
            break;
        
    }
}

-(void)enterDFU {
        __weak typeof(self) weakself = self;
        [self connectAndWrite:[NSString stringWithFormat:@"*dfu"] withCompletion:^(BOOL success, NSError *error) {
//            [weakself showAlertForAction:success error:error];
        }];
    
}

@end
