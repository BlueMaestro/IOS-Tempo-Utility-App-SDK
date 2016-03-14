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
	[_switchTemperatureUnit setOn:[TDDefaultDevice sharedDevice].selectedDevice.isFahrenheit.boolValue];
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
@end
