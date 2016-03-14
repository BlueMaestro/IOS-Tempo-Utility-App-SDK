//
//  TDSettingsViewController.m
//  TempoDisc
//
//  Created by Nikola Misic on 3/14/16.
//  Copyright © 2016 BlueMaestro. All rights reserved.
//

#import "TDSettingsViewController.h"
#import <LGBluetooth/LGBluetooth.h>

@interface TDSettingsViewController ()

@end

@implementation TDSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
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

- (IBAction)buttonBuzzClicked:(UIButton *)sender {
	/**
	 *	TDT-10 - just pput placeholder for now
	 **/
	return;
	if (sender.selected) {
		return;
	}
	else {
		sender.selected = YES;
		[[TDDefaultDevice sharedDevice].selectedDevice.peripheral connectWithCompletion:^(NSError *error) {
			if (!error) {
				[[TDDefaultDevice sharedDevice].selectedDevice.peripheral discoverServicesWithCompletion:^(NSArray *services, NSError *error) {
					if (!error) {
						if (services.count > 0) {
							for (LGService *service in services) {
								
							}
						}
						else {
							UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", nil) message:NSLocalizedString(@"No services found for find action", nil) preferredStyle:UIAlertControllerStyleAlert];
							[alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleCancel handler:nil]];
							[self presentViewController:alert animated:YES completion:nil];
						}
					}
					else {
						UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", nil) message:NSLocalizedString(@"Error discovering services for find action", nil) preferredStyle:UIAlertControllerStyleAlert];
						[alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleCancel handler:nil]];
						[self presentViewController:alert animated:YES completion:nil];
					}
				}];
			}
			else {
				UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", nil) message:NSLocalizedString(@"Error connecting to device for find action", nil) preferredStyle:UIAlertControllerStyleAlert];
				[alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleCancel handler:nil]];
				[self presentViewController:alert animated:YES completion:nil];
			}
		}];
	}
}
@end
