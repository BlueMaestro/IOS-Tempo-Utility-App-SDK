//
//  TDLivePlotViewController.m
//  Tempo Utility
//
//  Created by Nikola Misic on 11/19/16.
//  Copyright © 2016 BlueMaestro. All rights reserved.
//

#import "TDLivePlotViewController.h"
#import <CorePlot/ios/CorePlot.h>
#import "TDLivePlotData.h"
#import <LGBluetooth/LGBluetooth.h>
#import "TDDefaultDevice.h"
#import "TempoDiscDevice+CoreDataProperties.h"

#define kDeviceConnectTimeout			10.0
#define kDeviceReConnectTimeout			1.0

#define uartServiceUUIDString			@"6E400001-B5A3-F393-E0A9-E50E24DCCA9E"
#define uartRXCharacteristicUUIDString	@"6E400002-B5A3-F393-E0A9-E50E24DCCA9E"
#define uartTXCharacteristicUUIDString	@"6E400003-B5A3-F393-E0A9-E50E24DCCA9E"

@interface TDLivePlotViewController () <CPTScatterPlotDataSource, CPTScatterPlotDelegate, CPTPlotSpaceDelegate>

@property (strong, nonatomic) IBOutlet UIView *viewPlotContainer;

@property (nonatomic, strong) CPTGraphHostingView *hostView;

@property (nonatomic, strong) CPTGraph *graph;

@property (nonatomic, strong) CPTScatterPlot *plotTemperature;
@property (nonatomic, strong) CPTScatterPlot *plotHumidity;
@property (nonatomic, strong) CPTScatterPlot *plotDewPoint;

@property (nonatomic, strong) LGCharacteristic *writeCharacteristic;
@property (nonatomic, strong) LGCharacteristic *readCharacteristic;

@property (nonatomic, strong) NSMutableArray* dataSource;

@end

@implementation TDLivePlotViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	_dataSource = [NSMutableArray array];
	//initial data point
	TDLivePlotData *initialData = [[TDLivePlotData alloc] init];
	TempoDiscDevice *device = (TempoDiscDevice*)[TDDefaultDevice sharedDevice].selectedDevice;
	if ([device isKindOfClass:[TempoDiscDevice class]]) {
		initialData.temperature = device.currentTemperature;
		initialData.humidity = device.currentHumidity;
		initialData.dewPoint = device.dewPoint;
		initialData.timestamp = [NSDate date];
		[_dataSource addObject:initialData];
	}
	[self initPlot];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self adjustPlotsRange];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	[self setupDataDownload];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	if (_readCharacteristic) {
		[_readCharacteristic setNotifyValue:NO completion:^(NSError *error) {
			[[TDDefaultDevice sharedDevice].selectedDevice.peripheral disconnectWithCompletion:nil];
		}];
	}
	else {
		[[TDDefaultDevice sharedDevice].selectedDevice.peripheral disconnectWithCompletion:nil];
	}
	[[NSNotificationCenter defaultCenter] removeObserver:self name:kLGPeripheralDidDisconnect object:nil];
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

#pragma mark - Private methods

- (void)parseData:(NSData*)data {
	NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	if ([TDLivePlotData isValidData:dataString]) {
		TDLivePlotData *dataPoint = [[TDLivePlotData alloc] initWithString:dataString timestamp:[NSDate date]];
		[_dataSource addObject:dataPoint];
		[self adjustPlotsRange];
		
		[_plotTemperature insertDataAtIndex:_dataSource.count-1 numberOfRecords:1];
		[_plotTemperature reloadData];
		
		[_plotHumidity insertDataAtIndex:_dataSource.count-1 numberOfRecords:1];
		[_plotHumidity reloadData];
		
		[_plotDewPoint insertDataAtIndex:_dataSource.count-1 numberOfRecords:1];
		[_plotDewPoint reloadData];
	}
}

- (void)handleTimeout:(NSTimer*)timer {
	NSLog(@"Connect timeout reached");
}

- (void)handleDisconnectNotification:(NSNotification*)note {
	NSLog(@"Device disconnected");
	[self.navigationController popViewControllerAnimated:YES];
}

- (void)setupDataDownload {
	NSLog(@"Connecting to device...");
	__block NSTimer *timer = [NSTimer timerWithTimeInterval:kDeviceConnectTimeout target:self selector:@selector(handleTimeout:) userInfo:nil repeats:NO];
	[[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDisconnectNotification:) name:kLGPeripheralDidDisconnect object:nil];
	
	__weak typeof(self) weakself = self;
	[[LGCentralManager sharedInstance] scanForPeripheralsByInterval:kDeviceReConnectTimeout completion:^(NSArray *peripherals) {
		for (LGPeripheral *peripheral in peripherals) {
			if ([peripheral.UUIDString isEqualToString:[TDDefaultDevice sharedDevice].selectedDevice.peripheral.UUIDString]) {
				[TDDefaultDevice sharedDevice].selectedDevice.peripheral = peripheral;
				[[TDDefaultDevice sharedDevice].selectedDevice.peripheral connectWithTimeout:kDeviceConnectTimeout completion:^(NSError *error) {
					[timer invalidate];
					timer = nil;
//					weakself.didDisconnect = NO;
					if (!error) {
						NSLog(@"Connected to device");
						NSLog(@"Discovering device services...");
						[[TDDefaultDevice sharedDevice].selectedDevice.peripheral discoverServicesWithCompletion:^(NSArray *services, NSError *error2) {
							if (!error2) {
								NSLog(@"Discovered services");
								LGService *uartService;
								for (LGService* service in services) {
									if ([[service.UUIDString uppercaseString] isEqualToString:uartServiceUUIDString]) {
										uartService = service;
										NSLog(@"Found UART service: %@", service.UUIDString);
										NSLog(@"Discovering characteristics...");
										[service discoverCharacteristicsWithCompletion:^(NSArray *characteristics, NSError *error3) {
											if (!error3) {
												NSLog(@"Discovered characteristics");
												LGCharacteristic *readCharacteristic;
												for (LGCharacteristic *characteristic in characteristics) {
													if ([[characteristic.UUIDString uppercaseString] isEqualToString:uartTXCharacteristicUUIDString]) {
														NSLog(@"Found TX characteristic %@", characteristic.UUIDString);
														readCharacteristic = characteristic;
														weakself.readCharacteristic = characteristic;
														/*CBMutableCharacteristic *noteCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:readCharacteristic.UUIDString] properties:CBCharacteristicPropertyNotify+CBCharacteristicPropertyRead
														 value:nil permissions:CBAttributePermissionsReadable|CBAttributePermissionsWriteable];
														 LGCharacteristic *characteristicForNotification = [[LGCharacteristic alloc] initWithCharacteristic:noteCharacteristic];*/
														NSLog(@"Subscribing for TX characteristic notifications");
														[characteristic setNotifyValue:YES completion:^(NSError *error4) {
															if (!error4) {
																NSLog(@"Subscribed for TX characteristic notifications");
															}
															else {
																NSLog(@"Error subscribing for TX characteristic: %@", error4);
															}
														} onUpdate:^(NSData *data, NSError *error5) {
															if (!error5) {
																//													[weakself addLogMessage:[NSString stringWithFormat:@"%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]] type:LogMessageTypeInbound];
																//TODO: Parse data
																[weakself parseData:data];
															}
															else {
																NSLog(@"Error on updating TX data: %@", error5);
															}
														}];
													}
													else if ([[characteristic.UUIDString uppercaseString] isEqualToString:uartRXCharacteristicUUIDString]) {
														NSLog(@"Found RX characteristic %@", characteristic.UUIDString);
														weakself.writeCharacteristic = characteristic;
													}
												}
												if (!readCharacteristic) {
													NSLog(@"Could not find TX characteristic");
												}
												if (!weakself.writeCharacteristic) {
													NSLog(@"Could not find RX characteristic");
												}
												if (weakself.writeCharacteristic) {
													[weakself writeData:kLivePlotInitiateString toCharacteristic:weakself.writeCharacteristic];
												}
											}
											else {
												NSLog(@"Error discovering device characteristics: %@", error3);
											}
										}];
										break;
									}
								}
								if (!uartService) {
									NSLog(@"Failed to found UART service");
								}
							}
							else {
								NSLog(@"Error discovering device services: %@", error2);
							}
						}];
					}
					else {
						NSLog(@"Error connecting to device: %@", error);
					}
				}];
				break;
			}
		}
	}];
}

- (void)writeData:(NSString*)data toCharacteristic:(LGCharacteristic*)characteristic {
	NSLog(@"Writing data: %@ to characteristic: %@", data, characteristic.UUIDString);
	//	__weak typeof(self) weakself = self;
	[characteristic writeValue:[data dataUsingEncoding:NSUTF8StringEncoding] completion:^(NSError *error) {
		if (!error) {
			NSLog(@"Sucessefully wrote \"%@\" data to write characteristic", data);
		}
		else {
			NSLog(@"Error writing data to characteristic: %@", error);
		}
	}];
}

#pragma mark - Graph setup

- (void)adjustPlotsRange {
//	TempoDevice *device = [TDDefaultDevice sharedDevice].selectedDevice;
	/**
	 *	Adjust range for plot so that the last point is in the center with a few seconds to the left and right of the x axis
	 **/
	CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)_graph.defaultPlotSpace;
	TDLivePlotData *lastData = [_dataSource lastObject];
	
	double startPoint = lastData.timestamp.timeIntervalSince1970-(double)kLivePlotPaddingInSeconds;
	CPTPlotRange *newRange = [[CPTPlotRange alloc] initWithLocationDecimal:CPTDecimalFromDouble(startPoint) lengthDecimal:CPTDecimalFromFloat(kLivePlotWindowInSeconds)];
	//	plotSpace.xRange = newRange;
	[CPTAnimation animate:plotSpace property:@"xRange" fromPlotRange:plotSpace.xRange toPlotRange:newRange duration:0.3 animationCurve:CPTAnimationCurveLinear delegate:nil];
	
	plotSpace.xRange = newRange;
	plotSpace.yRange = [[CPTPlotRange alloc] initWithLocationDecimal:CPTDecimalFromFloat(kLivePlotMinXAxisValue) lengthDecimal:CPTDecimalFromFloat(kLivePlotMaxXAxisValue)];
}

-(void)initPlot
{
	_hostView = [self configureHost:_viewPlotContainer forGraph:_hostView];
	_graph = [self configureGraph:_graph hostView:_hostView graphView:_viewPlotContainer title:nil];
	_plotTemperature = [self configurePlot:_plotTemperature forGraph:_graph identifier:@"Temperature"];
	[self configureAxesForGraph:_graph plot:_plotTemperature lineColor:kColorLivePlotLineTemperature.CGColor];
	
	/*_hostViewHumidity = [self configureHost:_viewPlotContainer forGraph:_hostViewHumidity];
	_graphHumidity = [self configureGraph:_graphHumidity hostView:_hostViewHumidity graphView:_viewPlotContainer title:nil];*/
	_plotHumidity = [self configurePlot:_plotHumidity forGraph:_graph identifier:@"Humidity"];
	[self configureAxesForGraph:_graph plot:_plotHumidity lineColor:kColorLivePlotLineHumidty.CGColor];
	
	/*_hostViewDewPoint = [self configureHost:_viewPlotContainer forGraph:_hostViewDewPoint];
	_graphDewPoint = [self configureGraph:_graphDewPoint hostView:_hostViewDewPoint graphView:_viewPlotContainer title:nil];*/
	_plotDewPoint = [self configurePlot:_plotDewPoint forGraph:_graph identifier:@"DewPoint"];
	[self configureAxesForGraph:_graph plot:_plotDewPoint lineColor:kColorLivePlotLineDewPoint.CGColor];
}

-(CPTGraphHostingView*)configureHost:(UIView*)graphView forGraph:(CPTGraphHostingView*)host
{
	for (UIView* subview in graphView.subviews) {
		[subview removeFromSuperview];
	}
	host = [(CPTGraphHostingView *)[CPTGraphHostingView alloc] initWithFrame:CGRectInset(graphView.bounds, 10, 12)];
	host.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
	[graphView addSubview:host];
	return host;
}

- (CPTGraph*)configureGraph:(CPTGraph*)graph hostView:(CPTGraphHostingView*)hostView graphView:(UIView*)viewGraph title:(NSString*)title
{
	// 1 - Create the graph
	graph = [[CPTXYGraph alloc] initWithFrame:CGRectInset(viewGraph.bounds, 10, 10)];
	graph.title = title;
	graph.titleDisplacement = CGPointMake(0, 15.0);
	hostView.hostedGraph = graph;
	//	_graph.plotAreaFrame.plotArea.delegate = self;
	
	// Set up the look of the plot. Want
	[graph applyTheme:[CPTTheme themeNamed:kCPTDarkGradientTheme]];
	
	// Make things see through.
	graph.backgroundColor = nil;
	graph.fill = [CPTFill fillWithColor:[CPTColor whiteColor]];
	graph.plotAreaFrame.fill = nil;
	graph.plotAreaFrame.plotArea.fill = nil;
	graph.plotAreaFrame.borderLineStyle = nil;
	graph.plotAreaFrame.masksToBorder = NO;
	
	CPTMutableTextStyle *whiteText = [CPTMutableTextStyle textStyle];
	whiteText.color = [CPTColor colorWithComponentRed:62.0f/255.0f green:62.0f/255.0f blue:62.0f/255.0f alpha:1];
	whiteText.fontName=@"Montserrat-Regular";
	
	if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)
	{
		whiteText.fontSize=15;
	}
	else if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)//iPad
	{
		whiteText.fontSize=25;
	}
	
	graph.titleTextStyle = whiteText;
	
	hostView.allowPinchScaling = NO;
	
	/*UIPinchGestureRecognizer *pGes = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];
	[viewGraph addGestureRecognizer:pGes];*/
	
	return graph;
}

- (CPTScatterPlot*)configurePlot:(CPTScatterPlot*)plot forGraph:(CPTGraph*)graph identifier:(NSString*)identifier
{
	//plot average
	CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)graph.defaultPlotSpace;
	plotSpace.allowsUserInteraction = YES;
	plotSpace.delegate = self;
	
	// Set up the plot, including the look of the plot itself.
	plot = [self plotWithIdentifier:identifier];
	/*for (id plot in graph.allPlots) {
		[graph removePlot:plot];
	}*/
	[graph addPlot:plot toPlotSpace:plotSpace];
	
	return plot;
}

- (void)configureAxesForGraph:(CPTGraph*)graph plot:(CPTScatterPlot*)plot lineColor:(CGColorRef)color
{
	// Set up axis.
	CPTXYAxisSet * axisSet = (CPTXYAxisSet *) graph.axisSet;
	
	axisSet.xAxis.labelingPolicy = CPTAxisLabelingPolicyEqualDivisions;//CPTAxisLabelingPolicyAutomatic
	axisSet.xAxis.preferredNumberOfMajorTicks = 6;
	axisSet.xAxis.minorTickLineStyle = nil;
	axisSet.xAxis.axisConstraints = [CPTConstraints constraintWithLowerOffset:0.0];
	
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat:@"mm:ss"];
	CPTTimeFormatter *timeFormatter = [[CPTTimeFormatter alloc] initWithDateFormatter:formatter];
	timeFormatter.referenceDate = [NSDate dateWithTimeIntervalSince1970:0];
	[(CPTXYAxisSet *)graph.axisSet xAxis].labelFormatter = timeFormatter;
	
	axisSet.yAxis.labelingPolicy = CPTAxisLabelingPolicyAutomatic;
	    axisSet.yAxis.preferredNumberOfMajorTicks = 6;
	CPTMutableLineStyle *majorGridLineStyle = [CPTMutableLineStyle lineStyle];
	majorGridLineStyle.lineColor = [CPTColor colorWithGenericGray:0.7];
	majorGridLineStyle.lineWidth = 0.5;
	
	CPTMutableLineStyle *minorGridLineStyle = [CPTMutableLineStyle lineStyle];
	minorGridLineStyle.lineColor = [CPTColor colorWithGenericGray:0.8];
	minorGridLineStyle.lineWidth = 0.25;
	
	CPTMutableLineStyle *tickLineStyle = [CPTMutableLineStyle lineStyle];
	tickLineStyle.lineColor = [CPTColor colorWithGenericGray:0.1];
	tickLineStyle.lineWidth = 0.25;
	
	axisSet.yAxis.minorTickLineStyle = tickLineStyle;
	axisSet.yAxis.majorGridLineStyle = majorGridLineStyle;
	axisSet.yAxis.minorGridLineStyle = minorGridLineStyle;
	axisSet.yAxis.axisConstraints = [CPTConstraints constraintWithLowerOffset:0.0];
	
	NSNumberFormatter *formatterY = [[NSNumberFormatter alloc] init];
	[formatterY setNumberStyle:NSNumberFormatterDecimalStyle];
	[formatterY setGeneratesDecimalNumbers:NO];
	axisSet.yAxis.labelFormatter = formatterY;
	
	axisSet.yAxis.axisConstraints = [CPTConstraints constraintWithLowerOffset:0.0];
	
	CPTMutableTextStyle *labelTextStyle = [[CPTMutableTextStyle alloc] init];
	labelTextStyle.textAlignment = CPTTextAlignmentCenter;
	labelTextStyle.color = kColorGraphAxis;
	labelTextStyle.fontName=kFontGraphAxis;
	
	if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)
	{
		labelTextStyle.fontSize = kGraphiPhoneFontSize;
	}
	else if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)//iPad
	{
		labelTextStyle.fontSize = kGraphiPadFontSize;
	}
	
	axisSet.xAxis.labelTextStyle = labelTextStyle;
	axisSet.yAxis.labelTextStyle = labelTextStyle;
	
	//25-3
	CPTColor *linecolor = kColorGraphAverage;
	
	CPTMutableLineStyle *minrangeLineStyle = [plot.dataLineStyle mutableCopy];
	minrangeLineStyle.lineWidth = kGraphLineWidth;
	minrangeLineStyle.lineColor = [CPTColor colorWithCGColor:color];
	
	plot.dataLineStyle=minrangeLineStyle;
	plot.interpolation=GRAPH_LINE_TYPE;
	
	CPTMutableLineStyle *newSymbolLineStyle = [CPTMutableLineStyle lineStyle];
	newSymbolLineStyle.lineColor=kColorGraphAverage;
	newSymbolLineStyle.lineWidth=1.0;
	
	CPTPlotSymbol *temperatureSymbol = [CPTPlotSymbol ellipsePlotSymbol];  //dot symbol
	temperatureSymbol.lineStyle = minrangeLineStyle;
	temperatureSymbol.size=kGraphSymbolSize;
	temperatureSymbol.fill=[CPTFill fillWithColor:linecolor];
	temperatureSymbol.lineStyle = newSymbolLineStyle;
	plot.plotSymbol = temperatureSymbol;
	
}

- (CPTScatterPlot *)plotWithIdentifier:(NSString *)identifier
{
	// Set up the plot, including the look of the plot itself.
	CPTScatterPlot *plot = [[CPTScatterPlot alloc] init];
	plot.dataSource = self;
	plot.delegate = self;
	plot.identifier=identifier;
	plot.plotSymbolMarginForHitDetection = kGraphSymboldTouchArea;
	return plot;
}

#pragma mark - CPTScatterPlotDataSource

- (NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot
{
	return _dataSource.count;
}

- (NSNumber *) numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index
{
	TDLivePlotData *dataPoint = _dataSource[index];
	
	switch (fieldEnum) {
		case CPTScatterPlotFieldX:
			if (fieldEnum == CPTScatterPlotFieldX)
			{
				return [NSNumber numberWithDouble:[dataPoint.timestamp timeIntervalSince1970]];
			}
			break;
			
		case CPTScatterPlotFieldY:
			if ([plot.identifier isEqual:@"Temperature"]) {
				return dataPoint.temperature;
			}
			else if ([plot.identifier isEqual:@"Humidity"]) {
				return dataPoint.humidity;
			}
			else if ([plot.identifier isEqual:@"DewPoint"]) {
				return dataPoint.dewPoint;
			}
			
			break;
	}
	return [NSNumber numberWithFloat:0.0];
}

#pragma mark - CPTScatterPlotDelegate

- (CPTPlotSymbol *)symbolForScatterPlot:(CPTScatterPlot *)plot recordIndex:(NSUInteger)idx {
	CPTPlotSymbol *temperatureSymbol = [CPTPlotSymbol diamondPlotSymbol];
	temperatureSymbol.fill = [CPTFill fillWithColor:[CPTColor colorWithGenericGray:1.0]];
	return temperatureSymbol;
}

@end
