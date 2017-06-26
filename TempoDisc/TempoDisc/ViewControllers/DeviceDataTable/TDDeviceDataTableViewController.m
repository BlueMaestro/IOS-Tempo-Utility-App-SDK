//
//  TDDeviceDataTableViewController.m
//  TempoDisc
//
//  Created by Nikola Misic on 2/28/16.
//  Copyright © 2016 BlueMaestro. All rights reserved.
//

#import "TDDeviceDataTableViewController.h"
#import "Reading.h"
#import "TempoDiscDevice+CoreDataProperties.h"
#import "TDDiscDataTableViewCell.h"

@interface TDDeviceDataTableViewController ()

@property (nonatomic, strong) NSArray *dataSourceReadings;

@property (nonatomic, strong) NSDateFormatter *formatterTimestamp;

@property (nonatomic, strong) NSArray *dataSourceTemperature;
@property (nonatomic, strong) NSArray *dataSourceHumidity;
@property (nonatomic, strong) NSArray *dataSourcePressure;
@property (nonatomic, strong) NSArray *dataSourceDewPoint;
@property (nonatomic, strong) NSArray *dataSourceFirstMovement;
@property (nonatomic, strong) NSArray *dataSourceSecondMovement;
@property (nonatomic, strong) NSArray *dataSourceOpenClose;
@property (nonatomic, strong) NSArray *dataSourceLight;

@end

@implementation TDDeviceDataTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
	[self setupView];
	if ([TDSharedDevice sharedDevice].selectedDevice.version.integerValue == 32) {
		_currentReadingType = TempoReadingTypeFirstMovement;
	}
	else if ([TDSharedDevice sharedDevice].selectedDevice.version.integerValue == 52) {
		_currentReadingType = TempoReadingTypeOpenClose;
	}
	else if ([TDSharedDevice sharedDevice].selectedDevice.version.integerValue == 62) {
		_currentReadingType = TempoReadingTypeLight;
	}
	else {
		_currentReadingType = TempoReadingTypeTemperature;
	}
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self loadData];
	[self.tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
	self.parentViewController.navigationItem.rightBarButtonItem = nil;
}

#pragma mark - Private methods

- (void)setupView {
	self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
	_formatterTimestamp = [[NSDateFormatter alloc] init];
	if ([[TDSharedDevice sharedDevice].selectedDevice isKindOfClass:[TempoDiscDevice class]]) {
		_formatterTimestamp.dateFormat = @"yyyy MMMM dd : hh.mma";
	}
	else {
		_formatterTimestamp.dateFormat = @"hh:mm:ssa dd-MM-yyyy";
	}
}

- (void)loadData {
	if ([[TDSharedDevice sharedDevice].selectedDevice isKindOfClass:[TempoDiscDevice class]]) {
		[self loadDiscData];
	}
	else {
		[self loadDataForType:_currentReadingType];
	}
}

- (void)loadDiscData {
	if ([TDSharedDevice sharedDevice].selectedDevice.version.integerValue == 32) {
		_dataSourceFirstMovement= [self dataForType:TempoReadingTypeFirstMovement];
		_dataSourceSecondMovement = [self dataForType:TempoReadingTypeSecondMovement];
	}
	else if ([TDSharedDevice sharedDevice].selectedDevice.version.integerValue == 52) {
		_dataSourceOpenClose = [self dataForType:TempoReadingTypeOpenClose];
	}
	else if ([TDSharedDevice sharedDevice].selectedDevice.version.integerValue == 62) {
		_dataSourceLight = [self dataForType:TempoReadingTypeLight];
	}
	else {
		_dataSourceTemperature = [self dataForType:TempoReadingTypeTemperature];
		_dataSourceHumidity = [self dataForType:TempoReadingTypeHumidity];
		_dataSourcePressure = [self dataForType:TempoReadingTypePressure];
		_dataSourceDewPoint = [self dataForType:TempoReadingTypeDewPoint];
	}
}

- (NSArray*)dataForType:(TempoReadingType)type {
	NSString *readingType;
	switch (type) {
	    case TempoReadingTypeTemperature:
			readingType = @"Temperature";
			break;
		case TempoReadingTypeHumidity:
			readingType = @"Humidity";
		break;
		case TempoReadingTypePressure:
			readingType = @"Pressure";
			break;
		case TempoReadingTypeDewPoint:
			readingType = @"DewPoint";
		break;
		case TempoReadingTypeFirstMovement:
			readingType = @"FirstMovement";
			break;
		case TempoReadingTypeSecondMovement:
			readingType = @"SecondMovement";
			break;
		case TempoReadingTypeOpenClose:
			readingType = @"OpenClose";
			break;
		case TempoReadingTypeLight:
			readingType = @"Light";
			break;
	}
	if (readingType) {
		return [[[TDSharedDevice sharedDevice].selectedDevice readingsForType:readingType] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO]]];
	}
	else {
		return @[];
	}
}

- (void)loadDataForType:(TempoReadingType)type {
	_dataSourceReadings = [self dataForType:type];
	[self.tableView reloadData];
}

#pragma mark - Public methods

- (void)changeReadingType:(TempoReadingType)type {
	_currentReadingType = type;
	[self loadDataForType:_currentReadingType];
}

#pragma mark - Actions

- (IBAction)buttonChangeReadingTypeClicked:(UIBarButtonItem*)sender {
	if ([TDSharedDevice sharedDevice].selectedDevice.version.integerValue == 13 ||
		[TDSharedDevice sharedDevice].selectedDevice.version.integerValue == 52 ||
		[TDSharedDevice sharedDevice].selectedDevice.version.integerValue == 62) {
		return;
	}
	[self changeReadingType:_currentReadingType == TempoReadingTypeTemperature ? TempoReadingTypeHumidity : TempoReadingTypeTemperature];
	[sender setTitle:(_currentReadingType == TempoReadingTypeTemperature) ? @"Temperature" : @"Humidity"];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if ([TDSharedDevice sharedDevice].selectedDevice.version.integerValue == 32) {
		return _dataSourceFirstMovement.count;
	}
	else if ([TDSharedDevice sharedDevice].selectedDevice.version.integerValue == 52) {
		return _dataSourceOpenClose.count;
	}
	else if ([TDSharedDevice sharedDevice].selectedDevice.version.integerValue == 62) {
		return _dataSourceLight.count;
	}
	else if ([[TDSharedDevice sharedDevice].selectedDevice isKindOfClass:[TempoDiscDevice class]]) {
		return _dataSourceTemperature.count;
	}
	else {
		return _dataSourceReadings.count;
	}
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	if ([[TDSharedDevice sharedDevice].selectedDevice isKindOfClass:[TempoDiscDevice class]]) {
		NSString *reuse = @"cellDiscData";
		if (([TDSharedDevice sharedDevice].selectedDevice.version.integerValue == 13) ||
			([TDSharedDevice sharedDevice].selectedDevice.version.integerValue == 113) ||
			([TDSharedDevice sharedDevice].selectedDevice.version.integerValue == 52) ||
			([TDSharedDevice sharedDevice].selectedDevice.version.integerValue == 62)) {
			reuse = @"cellDiscData13";
		}
		else if (([TDSharedDevice sharedDevice].selectedDevice.version.integerValue == 27)) {
			reuse = @"cellDiscDataPressure";
		}
		if (([TDSharedDevice sharedDevice].selectedDevice.version.integerValue == 32)) {
			reuse = @"cellDiscData32";
		}
		
		TDDiscDataTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuse forIndexPath:indexPath];
		
		// Configure the cell...
		Reading *readingTemperature = indexPath.row < _dataSourceTemperature.count ? _dataSourceTemperature[indexPath.row] : nil;
		Reading *readingHumidity = indexPath.row < _dataSourceHumidity.count ? _dataSourceHumidity[indexPath.row] : nil;
		Reading *readingPressure = indexPath.row < _dataSourcePressure.count ? _dataSourcePressure[indexPath.row] : nil;
		Reading *readingDewPoint = indexPath.row < _dataSourceDewPoint.count ? _dataSourceDewPoint[indexPath.row] : nil;
		Reading *readingFirstMovement = indexPath.row < _dataSourceFirstMovement.count ? _dataSourceFirstMovement[indexPath.row] : nil;
		Reading *readingSecondMovement = indexPath.row < _dataSourceSecondMovement.count ? _dataSourceSecondMovement[indexPath.row] : nil;
		Reading *readingOpenClose = indexPath.row < _dataSourceOpenClose.count ? _dataSourceOpenClose[indexPath.row] : nil;
		Reading *readingLight = indexPath.row < _dataSourceLight.count ? _dataSourceLight[indexPath.row] : nil;
		
		NSString *unitSymbol = [NSString stringWithFormat:@"˚%@", [TDSharedDevice sharedDevice].selectedDevice.isFahrenheit.boolValue ? @"F" : @"C"];
		TempoDevice *selectedDevice = [TDSharedDevice sharedDevice].selectedDevice;
		
		if (readingTemperature) {
			cell.labelDateValue.text = [_formatterTimestamp stringFromDate:readingTemperature.timestamp];
			cell.labelTemperatureValue.text = [NSString stringWithFormat:@"%.1f%@", [TDHelper temperature:readingTemperature.avgValue forDevice:selectedDevice].floatValue, unitSymbol];
			cell.labelRecordNumberValue.text = @(_dataSourceTemperature.count - indexPath.row).stringValue;
		}
		
		if (readingHumidity) {
			cell.labelHumidityValue.text = [NSString stringWithFormat:@"%@%% RH", readingHumidity.avgValue];
		}
		else {
			cell.labelHumidityValue.text = @"";
		}
		if (readingPressure) {
			cell.labelPressureValue.text = [NSString stringWithFormat:@"%@ hPa", readingPressure.avgValue];
		}
		else {
			cell.labelPressureValue.text = @"";
		}
		if (readingDewPoint) {
			cell.labelDewPointValue.text = [NSString stringWithFormat:@"%.1f%@", [TDHelper temperature:readingDewPoint.avgValue forDevice:selectedDevice].floatValue, unitSymbol];
		}
		else {
			cell.labelDewPointValue.text = @"";
		}
		if (readingFirstMovement) {
			cell.labelChannelOneValue.text = readingFirstMovement.avgValue.stringValue;
			cell.labelDateValue.text = [_formatterTimestamp stringFromDate:readingFirstMovement.timestamp];
			cell.labelRecordNumberValue.text = @(_dataSourceFirstMovement.count - indexPath.row).stringValue;
		}
		else {
			cell.labelChannelOneValue.text = @"";
		}
		if (readingSecondMovement) {
			cell.labelChannelTwoValue.text = readingSecondMovement.avgValue.stringValue;
		}
		else {
			cell.labelChannelTwoValue.text = @"";
		}
		if (readingOpenClose) {
			cell.labelDateValue.text = [_formatterTimestamp stringFromDate:readingOpenClose.timestamp];
			cell.labelRecordNumberValue.text = @(_dataSourceOpenClose.count - indexPath.row).stringValue;
			cell.labelTemperature.text = [@"Number of Open Events:" uppercaseString];
			cell.labelTemperatureValue.text = @(readingOpenClose.avgValue.integerValue).stringValue;
		}
		else {
			cell.labelTemperature.text = [@"Number of Open Events:" uppercaseString];
			cell.labelTemperatureValue.text = @(readingOpenClose.avgValue.integerValue).stringValue;
		}
		if (readingLight) {
			cell.labelDateValue.text = [_formatterTimestamp stringFromDate:readingLight.timestamp];
			cell.labelRecordNumberValue.text = @(_dataSourceLight.count - indexPath.row).stringValue;
			cell.labelTemperature.text = [@"Lux Level:" uppercaseString];
			cell.labelTemperatureValue.text = @(readingLight.avgValue.integerValue).stringValue;
		}
		else {
			cell.labelTemperature.text = [@"Number of Open Events:" uppercaseString];
			cell.labelTemperatureValue.text = @(readingLight.avgValue.integerValue).stringValue;
		}
		
		return cell;
	}
	else {
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cellDataTable" forIndexPath:indexPath];
		
		// Configure the cell...
		Reading *reading = _dataSourceReadings[indexPath.row];
		
		if (reading.minValue || reading.maxValue) {
			if (_currentReadingType == TempoReadingTypeTemperature) {
				NSString *unitSymbol = [NSString stringWithFormat:@"˚%@", [TDSharedDevice sharedDevice].selectedDevice.isFahrenheit.boolValue ? @"F" : @"C"];
				TempoDevice *selectedDevice = [TDSharedDevice sharedDevice].selectedDevice;
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
	
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	if ([[TDSharedDevice sharedDevice].selectedDevice isKindOfClass:[TempoDiscDevice class]]) {
		if ([TDSharedDevice sharedDevice].selectedDevice.version.integerValue == 13 ||
			[TDSharedDevice sharedDevice].selectedDevice.version.integerValue == 113 ||
			[TDSharedDevice sharedDevice].selectedDevice.version.integerValue == 52 ||
			[TDSharedDevice sharedDevice].selectedDevice.version.integerValue == 62) {
			return 70;
		}
		else if ([TDSharedDevice sharedDevice].selectedDevice.version.integerValue == 27) {
			return 120;
		}
		else if ([TDSharedDevice sharedDevice].selectedDevice.version.integerValue == 32) {
			return 88;
		}
		else {
			return 104;
		}
	}
	else {
		return 44;
	}
}

@end
