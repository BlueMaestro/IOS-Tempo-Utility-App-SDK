//
//  TDSettingsViewController.m
//  TempoDisc
//
//  Created by Nikola Misic on 3/14/16.
//  Copyright © 2016 BlueMaestro. All rights reserved.
//

#import "TDSettingsViewController.h"
#import <LGBluetooth/LGBluetooth.h>
#import "AppDelegate.h"

@interface TDSettingsViewController ()

@property (nonatomic, strong) NSDate *todayAtMidnight;

@end

@implementation TDSettingsViewController

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
	[_switchTemperatureUnit setOn:[TDDefaultDevice sharedDevice].selectedDevice.isFahrenheit.boolValue];
	
	//set date to 00
	NSDateComponents *nowComponents = [[NSCalendar currentCalendar] components:(NSCalendarUnitEra | NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:[NSDate date]];
	[nowComponents setHour:0];
	[nowComponents setMinute:0];
	[nowComponents setSecond:0];
	_todayAtMidnight = [[NSCalendar currentCalendar] dateFromComponents:nowComponents];
	[_datePickerFrequency setDate:[_todayAtMidnight dateByAddingTimeInterval:60*15]];
}

#pragma mark - Actions

- (IBAction)buttonBuzzClicked:(UIButton *)sender {
	if (sender.selected) {
		return;
	}
	else {
		sender.selected = YES;
		unsigned char value = 1;
		[MBProgressHUD showHUDAddedTo:self.view animated:YES];
		[LGUtils writeData:[NSData dataWithBytes:&value length:sizeof(value)] charactUUID:@"20652011-02F3-4F75-848F-323AC2A6AF8A" serviceUUID:@"20652000-02F3-4F75-848F-323AC2A6AF8A" peripheral:[TDDefaultDevice sharedDevice].selectedDevice.peripheral completion:^(NSError *error) {
			[MBProgressHUD hideAllHUDsForView:self.view animated:NO];
			sender.selected = NO;
			if (!error) {
				UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Sucess", nil) message:NSLocalizedString(@"Wrote to find me characteristic", nil) preferredStyle:UIAlertControllerStyleAlert];
				[alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleCancel handler:nil]];
				[self presentViewController:alert animated:YES completion:nil];
			}
			else {
				UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", nil) message:[NSString stringWithFormat:NSLocalizedString(@"Error writing to find me characteristic: %@", nil), error] preferredStyle:UIAlertControllerStyleAlert];
				[alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleCancel handler:nil]];
				[self presentViewController:alert animated:YES completion:nil];
			}
		}];
	}
}

- (IBAction)switchTemperatureUnitValueChanged:(UISwitch *)sender {
	[TDDefaultDevice sharedDevice].selectedDevice.isFahrenheit = @(sender.isOn);
	NSManagedObjectContext *context = [(AppDelegate*)[UIApplication sharedApplication].delegate managedObjectContext];
	NSError *saveError;
	[context save:&saveError];
	if (saveError) {
		NSLog(@"Error saving temperature unit: %@", saveError);
	}
}

- (IBAction)datePickerFrequencyValueChanged:(UIDatePicker *)sender {
}

- (IBAction)buttonWriteFrequencyClicked:(UIButton *)sender {
	unsigned char data[2];
	NSNumber *newRate = @(-[_todayAtMidnight timeIntervalSinceDate:_datePickerFrequency.date]);
	data[0] = newRate.intValue&0xFF;
	data[1] = (newRate.intValue>> 8) &0xFF;
	[MBProgressHUD showHUDAddedTo:self.view animated:YES];
	[LGUtils writeData:[NSData dataWithBytes:&data length:sizeof(data)] charactUUID:@"20653010-02F3-4F75-848F-323AC2A6AF8A" serviceUUID:@"20652000-02F3-4F75-848F-323AC2A6AF8A" peripheral:[TDDefaultDevice sharedDevice].selectedDevice.peripheral completion:^(NSError *error) {
		[MBProgressHUD hideAllHUDsForView:self.view animated:NO];
		if (!error) {
			UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Sucess", nil) message:NSLocalizedString(@"Wrote to time sync me characteristic", nil) preferredStyle:UIAlertControllerStyleAlert];
			[alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleCancel handler:nil]];
			[self presentViewController:alert animated:YES completion:nil];
		}
		else {
			UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", nil) message:[NSString stringWithFormat:NSLocalizedString(@"Error writing to time sync characteristic: %@", nil), error] preferredStyle:UIAlertControllerStyleAlert];
			[alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleCancel handler:nil]];
			[self presentViewController:alert animated:YES completion:nil];
		}
	}];
}
@end
