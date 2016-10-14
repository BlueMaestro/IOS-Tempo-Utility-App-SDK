//
//  TDDevicesHistoryListTableViewController.m
//  Tempo Utility
//
//  Created by Nikola Misic on 10/13/16.
//  Copyright © 2016 BlueMaestro. All rights reserved.
//

#import "TDDevicesHistoryListTableViewController.h"
#import "AppDelegate.h"

@interface TDDevicesHistoryListTableViewController ()

@end

@implementation TDDevicesHistoryListTableViewController

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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	TempoDevice *selectedDevice = self.dataSource[indexPath.row];
	[TDDefaultDevice sharedDevice].selectedDevice = selectedDevice;
	[self.parentViewController.navigationController pushViewController:[self.storyboard instantiateViewControllerWithIdentifier:@"viewControllerGraph"] animated:YES];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}

- (NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
	__weak typeof(self) weakself = self;
	return @[[UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:NSLocalizedString(@"Delete", nil) handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
		dispatch_async(dispatch_get_main_queue(), ^{
			TempoDevice *device = weakself.dataSource[indexPath.row];
			NSManagedObjectContext *context = [(AppDelegate*)[UIApplication sharedApplication].delegate managedObjectContext];
			[context deleteObject:device];
			NSError *saveError;
			[context save:&saveError];
			if (saveError) {
				NSLog(@"Error deleting history device: %@", saveError.localizedDescription);
			}
			[weakself.tableView beginUpdates];
			[weakself.dataSource removeObjectAtIndex:indexPath.row];
			[weakself.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
			[weakself.tableView endUpdates];
		});
		
	}]];
}

@end
