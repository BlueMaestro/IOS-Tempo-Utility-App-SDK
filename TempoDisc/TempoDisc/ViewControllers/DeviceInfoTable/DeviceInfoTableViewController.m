//
//  DeviceInfoTableViewController.m
//  TempoDisc
//
//  Created by Nikola Misic on 9/21/16.
//  Copyright © 2016 BlueMaestro. All rights reserved.
//

#import "DeviceInfoTableViewController.h"
#import "TempoDiscDevice+CoreDataClass.h"
#import "TDHelper.h"

#define kKeySection @"kKeySection"
#define kKeySectionItems @"kKeySectionItems"

typedef enum : NSInteger {
	DevicePropertyUUID = 0,
	DevicePropertyVersion,
	DevicePropertyRSSI,
	DevicePropertyBattery,
	DevicePropertyLoggingInterval,
	DevicePropertyNumberOfRecords,
	DevicePropertyMode,
	DevicePropertyCurrentTemperature,
	DevicePropertyCurrentHumidity,
	DevicePropertyCurrentDew,
	DevicePropertyHighestTemperature,
	DevicePropertyHighestHumidity,
	DevicePropertyLowestTemperature,
	DevicePropertyLowestHumidity,
	DevicePropertyHighestDayTemperature,
	DevicePropertyHighestDayHumidity,
	DevicePropertyHighestDayDew,
	DevicePropertyAverageDayTemperature,
	DevicePropertyAverageDayHumidity,
	DevicePropertyAverageDayDew,
	DevicePropertyLowestDayTemperature,
	DevicePropertyLowestDayHumidity,
	DevicePropertyLowestDayDew,
	DevicePropertyNumberOfBreaches
} DevicePropertyField;

typedef enum : NSInteger {
	DevicePropertySectionNone,
	DevicePropertySectionCurrent,
	DevicePropertySectionHighestAndLowest,
	DevicePropertySectionLastDay,
	DevicePropertySectionThresholdBreaches
} DevicePropertySection;

@interface DeviceInfoTableViewController ()

@end

@implementation DeviceInfoTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
	
	_dataSource = @[@{kKeySection : @(DevicePropertySectionNone),
					  kKeySectionItems :
  @[@(DevicePropertyUUID), @(DevicePropertyVersion), @(DevicePropertyRSSI), @(DevicePropertyBattery), @(DevicePropertyLoggingInterval), @(DevicePropertyNumberOfRecords), @(DevicePropertyMode)]},
					@{kKeySection : @(DevicePropertySectionCurrent),
					  kKeySectionItems :
  @[@(DevicePropertyCurrentTemperature), @(DevicePropertyCurrentHumidity), @(DevicePropertyCurrentDew)]},
					@{kKeySection : @(DevicePropertySectionHighestAndLowest),
					  kKeySectionItems :
  @[@(DevicePropertyHighestTemperature), @(DevicePropertyHighestHumidity), @(DevicePropertyLowestTemperature), @(DevicePropertyLowestHumidity)]},
					  @{kKeySection : @(DevicePropertySectionLastDay),
						kKeySectionItems :
  @[@(DevicePropertyHighestDayTemperature), @(DevicePropertyLowestDayTemperature), @(DevicePropertyAverageDayTemperature), @(DevicePropertyHighestDayHumidity), @(DevicePropertyLowestDayHumidity), @(DevicePropertyAverageDayHumidity), @(DevicePropertyHighestDayDew), @(DevicePropertyLowestDayDew), @(DevicePropertyAverageDayDew)]},
					@{kKeySection : @(DevicePropertySectionThresholdBreaches),
					  kKeySectionItems :
  @[@(DevicePropertyNumberOfBreaches)]}
					];
	
	[self.tableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Private methods

- (NSString*)sectionTitleForDeviceInfo:(DevicePropertySection)section {
	switch (section) {
  case DevicePropertySectionNone:
			return @"";
			break;
		case DevicePropertySectionCurrent:
			return NSLocalizedString(@"CURRENT", nil);
			break;
		case DevicePropertySectionHighestAndLowest:
			return NSLocalizedString(@"HIGHEST AND LOWEST RECORDED", nil);
			break;
		case DevicePropertySectionLastDay:
			return NSLocalizedString(@"LAST 24 HOURS", nil);
			break;
		case DevicePropertySectionThresholdBreaches:
			return NSLocalizedString(@"THRESHOLD BREACHES", nil);
			break;
	}
	return @"";
}

- (NSString*)fieldTitleForItem:(DevicePropertyField)item {
	switch (item) {
		case DevicePropertyUUID:
			return NSLocalizedString(@"UUID:", nil);
			break;
		case DevicePropertyVersion:
			return NSLocalizedString(@"VERSION:", nil);
			break;
		case DevicePropertyRSSI:
			return NSLocalizedString(@"RSSI:", nil);
			break;
		case DevicePropertyBattery:
			return NSLocalizedString(@"BATTERY:", nil);
			break;
		case DevicePropertyLoggingInterval:
			return NSLocalizedString(@"LOGGING INTERVAL:", nil);
			break;
		case DevicePropertyNumberOfRecords:
			return NSLocalizedString(@"NUMBER OF RECORDS:", nil);
			break;
		case DevicePropertyMode:
			return NSLocalizedString(@"MODE:", nil);
			break;
		case DevicePropertyCurrentTemperature:
			return NSLocalizedString(@"TEMPERATURE:", nil);
			break;
		case DevicePropertyCurrentHumidity:
			return NSLocalizedString(@"HUMIDITY:", nil);
			break;
		case DevicePropertyCurrentDew:
			return NSLocalizedString(@"DEW POINT:", nil);
			break;
		case DevicePropertyHighestTemperature:
			return NSLocalizedString(@"HIGHEST TEMPERATURE:", nil);
			break;
		case DevicePropertyHighestHumidity:
			return NSLocalizedString(@"HIGHEST HUMIDITY:", nil);
			break;
		case DevicePropertyLowestTemperature:
			return NSLocalizedString(@"LOWEST TEMPERATURE:", nil);
			break;
		case DevicePropertyLowestHumidity:
			return NSLocalizedString(@"LOWEST HUMIDITY:", nil);
			break;
		case DevicePropertyHighestDayTemperature:
			return NSLocalizedString(@"HIGHEST TEMPERATURE:", nil);
			break;
		case DevicePropertyHighestDayHumidity:
			return NSLocalizedString(@"HIGHEST HUMIDITY:", nil);
			break;
		case DevicePropertyHighestDayDew:
			return NSLocalizedString(@"HIGHEST DEW POINT:", nil);
			break;
		case DevicePropertyAverageDayTemperature:
			return NSLocalizedString(@"AVERAGE TEMPERATURE:", nil);
			break;
		case DevicePropertyAverageDayHumidity:
			return NSLocalizedString(@"AVERAGE HUMIDITY:", nil);
			break;
		case DevicePropertyAverageDayDew:
			return NSLocalizedString(@"AVERAGE DEW POINT:", nil);
			break;
		case DevicePropertyLowestDayTemperature:
			return NSLocalizedString(@"LOWEST TEMPERATURE:", nil);
			break;
		case DevicePropertyLowestDayHumidity:
			return NSLocalizedString(@"LOWEST HUMIDITY:", nil);
			break;
		case DevicePropertyLowestDayDew:
			return NSLocalizedString(@"LOWEST DEW POINT:", nil);
			break;
		case DevicePropertyNumberOfBreaches:
			return NSLocalizedString(@"NUMBER OF BREACHES:", nil);
			break;
	}
	return @"";
}

- (NSString*)valueForField:(DevicePropertyField)item device:(TempoDiscDevice*)device {
	NSString *unit = device.isFahrenheit.boolValue ? @"˚Fahrenheit" : @"˚Celsius";
	switch (item) {
		case DevicePropertyUUID:
			return device.uuid;
			break;
		case DevicePropertyVersion:
			return device.version;
			break;
		case DevicePropertyRSSI:
			return [NSString stringWithFormat:@"%ld dBm", (long)device.peripheral.RSSI];
			break;
		case DevicePropertyBattery:
			return [NSString stringWithFormat:@"%@%%", device.battery.stringValue];
			break;
		case DevicePropertyLoggingInterval:
			return [NSString stringWithFormat:@"%@ seconds", device.timerInterval];
			break;
		case DevicePropertyNumberOfRecords:
			return @(device.intervalCounter.integerValue).stringValue;
			break;
		case DevicePropertyMode:
			return device.mode.stringValue;
			break;
		case DevicePropertyCurrentTemperature:
			return [NSString stringWithFormat:@"%@ %@", device.currentTemperature, unit];
			break;
		case DevicePropertyCurrentHumidity:
			return [NSString stringWithFormat:@"%@%% RH ", device.currentHumidity];
			break;
		case DevicePropertyCurrentDew:
			return [NSString stringWithFormat:@"%@ %@", device.dewPoint, unit];
			break;
		case DevicePropertyHighestTemperature:
			return [NSString stringWithFormat:@"%@ %@", device.highestTemperature, unit];
			break;
		case DevicePropertyHighestHumidity:
			return [NSString stringWithFormat:@"%@%% RH", device.highestHumidity];
			break;
		case DevicePropertyLowestTemperature:
			return [NSString stringWithFormat:@"%@ %@", device.lowestTemperature, unit];
			break;
		case DevicePropertyLowestHumidity:
			return [NSString stringWithFormat:@"%@%% RH", device.lowestHumidity];
			break;
		case DevicePropertyHighestDayTemperature:
			return [NSString stringWithFormat:@"%@ %@", device.highestDayTemperature, unit];
			break;
		case DevicePropertyHighestDayHumidity:
			return [NSString stringWithFormat:@"%@%% RH", device.highestDayHumidity];
			break;
		case DevicePropertyHighestDayDew:
			return [NSString stringWithFormat:@"%@ %@", device.highestDayDew, unit];
			break;
		case DevicePropertyAverageDayTemperature:
			return [NSString stringWithFormat:@"%@ %@", device.averageDayTemperature, unit];
			break;
		case DevicePropertyAverageDayHumidity:
			return [NSString stringWithFormat:@"%@%% RH", device.averageDayHumidity];
			break;
		case DevicePropertyAverageDayDew:
			return [NSString stringWithFormat:@"%@ %@", device.averageDayDew, unit];
			break;
		case DevicePropertyLowestDayTemperature:
			return [NSString stringWithFormat:@"%@ %@", device.lowestDayTemperature, unit];
			break;
		case DevicePropertyLowestDayHumidity:
			return [NSString stringWithFormat:@"%@%% RH", device.lowestDayHumidity];
			break;
		case DevicePropertyLowestDayDew:
			return [NSString stringWithFormat:@"%@ %@", device.lowestDayDew, unit];
			break;
		case DevicePropertyNumberOfBreaches:
			return device.numBreach.stringValue;
			break;
	}
	return @"";
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return _dataSource.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_dataSource[section][kKeySectionItems] count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cellDevice" forIndexPath:indexPath];
    
    // Configure the cell...
	NSString *title = [self fieldTitleForItem:[_dataSource[indexPath.section][kKeySectionItems][indexPath.row] integerValue]];
	NSString *value = [self valueForField:[_dataSource[indexPath.section][kKeySectionItems][indexPath.row] integerValue] device:(TempoDiscDevice*)[TDDefaultDevice sharedDevice].selectedDevice];
	
	NSString *text = [NSString stringWithFormat:@"%@ %@", title, value];
	NSMutableAttributedString *attributedTitle = [[NSMutableAttributedString alloc] initWithString:text attributes:@{NSFontAttributeName : [UIFont regularFontWithSize:12.0], NSForegroundColorAttributeName : [UIColor botomBarSeparatorGrey]}];
	[attributedTitle addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:[text rangeOfString:title]];
	
	cell.textLabel.attributedText = attributedTitle;
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	return [self sectionTitleForDeviceInfo:[_dataSource[section][kKeySection] integerValue]];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 22.0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	UIView *sectionView = [[UIView alloc] initWithFrame:CGRectZero];
	sectionView.backgroundColor = [UIColor whiteColor];
	
	UILabel *sectionLabel = [[UILabel alloc] initWithFrame:CGRectZero];
	sectionLabel.translatesAutoresizingMaskIntoConstraints = NO;
	sectionLabel.font = [UIFont regularFontWithSize:15.0];
	sectionLabel.backgroundColor = [UIColor whiteColor];
	sectionLabel.text = [self sectionTitleForDeviceInfo:[_dataSource[section][kKeySection] integerValue]];
	
	[sectionView addSubview:sectionLabel];
	[sectionView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[sectionLabel]-0-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(sectionLabel)]];
	[sectionView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-16-[sectionLabel]-8-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(sectionLabel)]];
	
	return sectionView;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
