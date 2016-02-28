//
//  TDDeviceListTableViewController.m
//  TempoDisc
//
//  Created by Nikola Misic on 2/28/16.
//  Copyright © 2016 BlueMaestro. All rights reserved.
//

#import "TDDeviceListTableViewController.h"
#import <LGBluetooth/LGBluetooth.h>

@interface TDDeviceListTableViewController()

@property (nonatomic, strong) NSArray *dataSource;

@end

@implementation TDDeviceListTableViewController

- (void)viewDidLoad {
	
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return _dataSource.count;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cellDevice" forIndexPath:indexPath];
	
	return cell;
}


@end
