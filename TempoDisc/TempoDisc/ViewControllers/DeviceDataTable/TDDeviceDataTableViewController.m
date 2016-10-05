//
//  TDDeviceDataTableViewController.m
//  TempoDisc
//
//  Created by Nikola Misic on 2/28/16.
//  Copyright © 2016 BlueMaestro. All rights reserved.
//

#import "TDDeviceDataTableViewController.h"
#import "Reading.h"

@interface TDDeviceDataTableViewController ()

@property (nonatomic, strong) NSArray *dataSourceReadings;

@property (nonatomic, strong) NSDateFormatter *formatterTimestamp;

@end

@implementation TDDeviceDataTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
	[self setupView];
	_currentReadingType = TempoReadingTypeTemperature;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self loadDataForType:_currentReadingType];
//	self.parentViewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Temperature" style:UIBarButtonItemStyleDone target:self action:@selector(buttonChangeReadingTypeClicked:)];
	[self.tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
	self.parentViewController.navigationItem.rightBarButtonItem = nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Private methods

- (void)setupView {
	self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
	_formatterTimestamp = [[NSDateFormatter alloc] init];
	_formatterTimestamp.dateFormat = @"hh:mm:ssa dd-MM-yyyy";
}

- (void)loadDataForType:(TempoReadingType)type {
	NSString *readingType;
	switch (type) {
  case TempoReadingTypeTemperature:
			readingType = @"Temperature";
			break;
		case TempoReadingTypeHumidity:
			readingType = @"Humidity";
		case TempoReadingTypeDewPoint:
			readingType = @"DewPoint";
			
  default:
			break;
	}
	if (readingType) {
		_dataSourceReadings = [[[TDDefaultDevice sharedDevice].selectedDevice readingsForType:readingType] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO]]];
	}
	else {
		_dataSourceReadings = @[];
	}
	[self.tableView reloadData];
}

#pragma mark - Public methods

- (void)changeReadingType:(TempoReadingType)type {
	_currentReadingType = type;
	[self loadDataForType:_currentReadingType];
}

#pragma mark - Actions

- (IBAction)buttonChangeReadingTypeClicked:(UIBarButtonItem*)sender {
	[self changeReadingType:_currentReadingType == TempoReadingTypeTemperature ? TempoReadingTypeHumidity : TempoReadingTypeTemperature];
	[sender setTitle:(_currentReadingType == TempoReadingTypeTemperature) ? @"Temperature" : @"Humidity"];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _dataSourceReadings.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cellDataTable" forIndexPath:indexPath];
    
    // Configure the cell...
	Reading *reading = _dataSourceReadings[indexPath.row];
	
	if (reading.minValue || reading.maxValue) {
		if (_currentReadingType == TempoReadingTypeTemperature) {
			NSString *unitSymbol = [NSString stringWithFormat:@"˚%@", [TDDefaultDevice sharedDevice].selectedDevice.isFahrenheit.boolValue ? @"F" : @"C"];
			TempoDevice *selectedDevice = [TDDefaultDevice sharedDevice].selectedDevice;
			cell.textLabel.text = [NSString stringWithFormat:@"avg: %@%@, min: %@%@, max: %@%@", [TDHelper temperature:reading.avgValue forDevice:selectedDevice].stringValue, unitSymbol, [TDHelper temperature:reading.minValue forDevice:selectedDevice].stringValue, unitSymbol, [TDHelper temperature:reading.maxValue forDevice:selectedDevice].stringValue, unitSymbol];
		}
		else {
			cell.textLabel.text = [NSString stringWithFormat:@"avg: %@, min: %@, max: %@", reading.avgValue.stringValue, reading.minValue.stringValue, reading.maxValue.stringValue];
		}
	}
	else {
		cell.textLabel.text = [NSString stringWithFormat:@"avg: %@", reading.avgValue.stringValue];
	}
	cell.detailTextLabel.text = [_formatterTimestamp stringFromDate:reading.timestamp];
    
    return cell;
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
