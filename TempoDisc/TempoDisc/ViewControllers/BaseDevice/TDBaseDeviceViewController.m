//
//  TDBaseDeviceViewController.m
//  TempoDisc
//
//  Created by Nikola Misic on 7/26/16.
//  Copyright © 2016 BlueMaestro. All rights reserved.
//

#import "TDBaseDeviceViewController.h"
#import <LGCentralManager.h>
#import "TDDefaultDevice.h"

@implementation TDBaseDeviceViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	[self setupView];
}

- (void)setupView {
	for (UIButton *button in _buttonOptions) {
		button.layer.cornerRadius = 4.0;
		button.clipsToBounds = YES;
		button.layer.borderWidth = 1;
		button.layer.borderColor = [UIColor buttonSeparator].CGColor;
		[button setBackgroundImage:[[SCHelper imageWithColor:[UIColor buttonDarkGrey]] resizableImageWithCapInsets:UIEdgeInsetsZero]  forState:UIControlStateNormal];
		[button setBackgroundImage:[[SCHelper imageWithColor:[UIColor lightGrayColor]] resizableImageWithCapInsets:UIEdgeInsetsZero]  forState:UIControlStateHighlighted];
		[button setBackgroundImage:[[SCHelper imageWithColor:[UIColor lightGrayColor]] resizableImageWithCapInsets:UIEdgeInsetsZero]  forState:UIControlStateSelected];
		[button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
		[button setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
		[button setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
		button.titleLabel.numberOfLines = 2;
		button.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
		button.titleLabel.textAlignment = NSTextAlignmentCenter;
	}
	
	_labelDeviceName.text = [TDDefaultDevice sharedDevice].selectedDevice.name;
	
	self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Back", nil) style:UIBarButtonItemStyleDone target:nil action:nil];
}

- (void)refreshCurrentDevice {
	[[LGCentralManager sharedInstance] scanForPeripheralsByInterval:1 completion:^(NSArray *peripherals) {
		for (LGPeripheral *peripheral in peripherals) {
			if ([peripheral.UUIDString isEqualToString:[TDDefaultDevice sharedDevice].selectedDevice.peripheral.UUIDString]) {
				[TDDefaultDevice sharedDevice].selectedDevice.peripheral = peripheral;
				NSLog(@"Rescanned for device: %@", peripheral.UUIDString);
				[[NSNotificationCenter defaultCenter] postNotificationName:kNotificationPeripheralUpdated object:nil userInfo:@{kKeyNotificationPeripheralUpdatedPeripheral : peripheral}];
				break;
			}
		}
	}];
}

@end
