//
//  TDDeviceTableContainer.m
//  TempoDisc
//
//  Created by Nikola Misic on 7/26/16.
//  Copyright © 2016 BlueMaestro. All rights reserved.
//

#import "TDDeviceTableContainer.h"
#import "TDDeviceDataTableViewController.h"
#import <MessageUI/MFMailComposeViewController.h>
#import "CHCSVParser.h"
#import <MBProgressHUD.h>
#import "TempoDiscDevice+CoreDataProperties.h"

@interface TDDeviceTableContainer() <MFMailComposeViewControllerDelegate>

@property (nonatomic, strong) TDDeviceDataTableViewController *controllerDeviceTable;

@end

@implementation TDDeviceTableContainer

- (void)viewDidLoad {
	[super viewDidLoad];
	[self setupView];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.destinationViewController isKindOfClass:[TDDeviceDataTableViewController class]]) {
		_controllerDeviceTable = segue.destinationViewController;
	}
}

#pragma mark - Private methods

- (void)setupView {
	[super setupView];
	for (UIButton *button in _buttonsBottomMenu) {
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
	_viewBottomMenuContainer.layer.borderColor = [UIColor botomBarSeparatorGrey].CGColor;
	_viewBottomMenuContainer.layer.borderWidth = 1;
}

- (void)adjustedButtonTitles {
	NSString *title = @"";
	switch (_controllerDeviceTable.currentReadingType) {
		case TempoReadingTypeTemperature:
			title = @"Temperature data";
			break;
		case TempoReadingTypeHumidity:
			title = @"Humidity data";
			break;
		case TempoReadingTypeDewPoint:
			title = @"Dew point data";
			break;
			
  default:
			break;
	}
	[_buttonReadingType setTitle:title forState:UIControlStateNormal];
	[_buttonReadingType setTitle:title forState:UIControlStateSelected];
	[_buttonReadingType setTitle:title forState:UIControlStateHighlighted];
}

-(void)createCSVFile:(NSString*)fileName{
	NSOutputStream *output = [NSOutputStream outputStreamToMemory];
	CHCSVWriter *writer = [[CHCSVWriter alloc] initWithOutputStream:output encoding:NSUTF8StringEncoding delimiter:','];
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat:@"HH:mm\tdd/MM/yyyy"];
	
	//write pre values data
	TempoDiscDevice *device = (TempoDiscDevice*)[TDDefaultDevice sharedDevice].selectedDevice;
	[writer writeField:@"Current Date and Time"];
	[writer writeField:[formatter stringFromDate:[NSDate date]]];
	[writer finishLine];
	[writer writeField:@"Device Name"];
	[writer writeField:device.name];
	[writer finishLine];
	[writer writeField:@"Device UUID"];
	[writer writeField:device.uuid];
	[writer finishLine];
	[writer writeField:@"Class ID"];
	[writer writeField:[NSString stringWithFormat:@"%ld", (long)device.globalIdentifier.integerValue]];
	[writer finishLine];
	[writer writeField:@"Battery Level"];
	[writer writeField:[NSString stringWithFormat:@"%.2f", device.battery.floatValue]];
	[writer finishLine];
	[writer writeField:@"Radio Strength"];
	[writer writeField:[NSString stringWithFormat:@"%ld", (long)device.peripheral.RSSI]];
	[writer finishLine];
	[writer writeField:@"Reference Date"];
	[writer writeField:[formatter stringFromDate:device.startTimestamp]];
	[writer finishLine];
	[writer writeField:@"Last Download Date"];
	[writer writeField:[formatter stringFromDate:device.lastDownload]];
	[writer finishLine];
	[writer writeField:@"The number of alert thresholds registered"];
	[writer writeField:[NSString stringWithFormat:@"%ld", (long)device.numBreach.integerValue]];
	[writer finishLine];
	[writer writeField:@"Temperature Unit"];
	[writer writeField:device.isFahrenheit.boolValue ? @"Fahrenheit" : @"Celsius"];
	[writer finishLine];
	[writer finishLine];
	
	//wrting header name for csv file
	[writer writeField:@"Record number"];
	[writer writeField:@"Timestamp"];
	[writer writeField:@"Temperature"];
	[writer writeField:@"Humidity"];
	[writer writeField:@"Dew point"];
	[writer finishLine];
	
	
	//[formatter setDateFormat:@"dd/MM/yyyy\tHH:mm"];
	NSArray *temperature = [[device readingsForType:@"Temperature"] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO]]];
	NSArray *humidity = [[device readingsForType:@"Humidity"] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO]]];
	NSArray *dewPoint = [[device readingsForType:@"DewPoint"] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO]]];
    
    for (NSInteger index = (temperature.count - 1); index >= 0; index--) {
		Reading *readingTemperature = index >= 0 ? temperature[index] : nil;
		Reading *readingHumidity = index >= 0 ? humidity[index] : nil;
		Reading *readingDewPoint = index >= 0 ? dewPoint[index] : nil;
		
		[writer writeField:[NSString stringWithFormat:@"%lu", (unsigned long)index]];
		[writer writeField:[NSString stringWithFormat:@"%@", [formatter stringFromDate:readingTemperature.timestamp]]];
		[writer writeField:[NSString stringWithFormat:@"%@", [TDHelper temperature:readingTemperature.avgValue forDevice:device]]];
		[writer writeField:[NSString stringWithFormat:@"%@", readingHumidity.avgValue]];
		[writer writeField:[NSString stringWithFormat:@"%@", [TDHelper temperature:readingDewPoint.avgValue forDevice:device]]];
		[writer finishLine];
	}
	
	[writer closeStream];
	
	NSData *buffer = [output propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
	[[NSFileManager defaultManager] createFileAtPath:fileName
											contents:buffer
										  attributes:nil];
}

-(NSString*)createFileNameWithAttachmentType:(NSString *)type withPath:(BOOL)includePath
{
	NSString* fileName;
	
	fileName = @"exportData";
	
	if (includePath) {
		NSArray *arrayPaths =
		NSSearchPathForDirectoriesInDomains(
											NSDocumentDirectory,
											NSUserDomainMask,
											YES);
		NSString *path = [arrayPaths objectAtIndex:0];
		NSString* pdfFileName = [path stringByAppendingPathComponent:fileName];
		
		return pdfFileName;
	}
	
	return fileName;
	
}

#pragma mark - Actions

- (IBAction)buttonExportPdfClicked:(UIButton *)sender {
}

- (IBAction)buttonExportCSVClicked:(UIButton *)sender {
	if ([MFMailComposeViewController canSendMail]) {
		[MBProgressHUD showHUDAddedTo:self.view animated:YES];
		MFMailComposeViewController *mailComposeVC = [[MFMailComposeViewController alloc] init];
		mailComposeVC.mailComposeDelegate = self;
		mailComposeVC.modalPresentationStyle = UIModalPresentationPageSheet;
		/*[mailComposeVC.navigationBar setTintColor:[UIColor blueMaestroBlue]];
		 [mailComposeVC.navigationBar setTitleTextAttributes:
		 [NSDictionary dictionaryWithObjectsAndKeys:
	  [UIColor whiteColor],
	  NSForegroundColorAttributeName,
	  nil]];
		 [mailComposeVC setNeedsStatusBarAppearanceUpdate];*/
		[mailComposeVC setSubject:@"Data Export"];
		
		NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
		[formatter setDateFormat:@"dd-MM-yyyy"];
		
		NSString *fileName = [self createFileNameWithAttachmentType:@"CSV" withPath:YES];
		[self createCSVFile:fileName];
		NSData * csvData=[NSData dataWithContentsOfFile:fileName];
		[mailComposeVC addAttachmentData:csvData mimeType:@"text/csv" fileName:[NSString stringWithFormat:@"%@-%@", [TDDefaultDevice sharedDevice].selectedDevice.name, [formatter stringFromDate:[NSDate date]]]];
		
		[MBProgressHUD hideHUDForView:self.view animated:NO];
		[self presentViewController:mailComposeVC animated:YES completion:nil];
	}
	else {
		UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error" message:@"There are no email accounts setup for this device" preferredStyle:UIAlertControllerStyleAlert];
		[alert addAction:[UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleCancel handler:nil]];
		[self presentViewController:alert animated:YES completion:nil];
	}
}

- (IBAction)buttonChangeReadingTypeClicked:(UIButton *)sender {
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"READING TYPE", nil) message:NSLocalizedString(@"Choose reading type", nil) preferredStyle:UIAlertControllerStyleActionSheet];
	__weak typeof(self) weakself = self;
	[alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Temperature", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
		[weakself.controllerDeviceTable changeReadingType:TempoReadingTypeTemperature];
		[weakself adjustedButtonTitles];
	}]];
	[alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Humidity", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
		[weakself.controllerDeviceTable changeReadingType:TempoReadingTypeHumidity];
		[weakself adjustedButtonTitles];
	}]];
	[alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Dew Point", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
		[weakself.controllerDeviceTable changeReadingType:TempoReadingTypeDewPoint];
		[weakself adjustedButtonTitles];
	}]];
	[alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil]];
	[self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
	[controller dismissViewControllerAnimated:YES completion:nil];
}

@end
