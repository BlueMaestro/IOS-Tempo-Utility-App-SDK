//
//  TDBaseDeviceViewController.m
//  TempoDisc
//
//  Created by Nikola Misic on 7/26/16.
//  Copyright © 2016 BlueMaestro. All rights reserved.
//

#import "TDBaseDeviceViewController.h"

@implementation TDBaseDeviceViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	[self setupView];
}

- (void)setupView {
	for (UIButton *button in _buttonOptions) {
		button.layer.cornerRadius = 8.0;
		button.clipsToBounds = YES;
		button.layer.borderWidth = 2;
		button.layer.borderColor = [UIColor blueMaestroBlue].CGColor;
		[button setBackgroundImage:[[SCHelper imageWithColor:button.backgroundColor] resizableImageWithCapInsets:UIEdgeInsetsZero]  forState:UIControlStateNormal];
		[button setBackgroundImage:[[SCHelper imageWithColor:[UIColor blueMaestroBlue]] resizableImageWithCapInsets:UIEdgeInsetsZero]  forState:UIControlStateHighlighted];
		[button setBackgroundImage:[[SCHelper imageWithColor:[UIColor blueMaestroBlue]] resizableImageWithCapInsets:UIEdgeInsetsZero]  forState:UIControlStateSelected];
		[button setTitleColor:[UIColor blueMaestroBlue] forState:UIControlStateNormal];
		[button setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
		[button setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
		button.titleLabel.numberOfLines = 2;
		button.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
		button.titleLabel.textAlignment = NSTextAlignmentCenter;
	}
	
	_labelDeviceName.text = [TDDefaultDevice sharedDevice].selectedDevice.name;
}

@end
