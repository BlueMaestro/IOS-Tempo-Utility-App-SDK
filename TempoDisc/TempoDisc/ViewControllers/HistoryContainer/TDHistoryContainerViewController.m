//
//  TDHistoryContainerViewController.m
//  TempoDisc
//
//  Created by Nikola Misic on 10/6/16.
//  Copyright © 2016 BlueMaestro. All rights reserved.
//

#import "TDHistoryContainerViewController.h"
#import "TempoDiscDevice+CoreDataProperties.h"
#import "AppDelegate.h"

@interface TDHistoryContainerViewController ()

@end

@implementation TDHistoryContainerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	[self loadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
	[super prepareForSegue:segue sender:sender];
	if (self.controllerDeviceList) {
		self.controllerDeviceList.ignoreScan = YES;
	}
}


#pragma mark - Overrides

- (void)setupView {
	[super setupView];
	self.navigationItem.rightBarButtonItem = nil;
	self.navigationItem.leftBarButtonItem = nil;
	self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Back", nil) style:UIBarButtonItemStyleDone target:nil action:nil];
}

#pragma mark - Private methods

- (void)loadData {
	NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([TempoDiscDevice class])];
	request.predicate = [NSPredicate predicateWithFormat:@"readingTypes.@count > 0"];
	NSArray *result = [[(AppDelegate*)[UIApplication sharedApplication].delegate managedObjectContext] executeFetchRequest:request error:nil];
	[self.controllerDeviceList loadDevices:result];
}

#pragma mark - Actions

- (IBAction)buttonBackClicked:(id)sender {
	[self.navigationController popViewControllerAnimated:YES];
}

@end
