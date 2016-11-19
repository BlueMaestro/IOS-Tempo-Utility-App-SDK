//
//  TDGraphViewController.m
//  TempoDisc
//
//  Created by Nikola Misic on 3/10/16.
//  Copyright © 2016 BlueMaestro. All rights reserved.
//

#import "TDGraphViewController.h"
#import <CorePlot/ios/CorePlot.h>
#import "IBActionSheet.h"

#define kTresholdZoomAngle 30

#define kInitialDataLoadCount 140

@interface TDGraphViewController () <CPTScatterPlotDataSource, CPTScatterPlotDelegate, CPTPlotSpaceDelegate, IBActionSheetDelegate>

@property (nonatomic, strong) CPTGraphHostingView *hostViewTemperature;
@property (nonatomic, strong) CPTGraphHostingView *hostViewHumidity;
@property (nonatomic, strong) CPTGraphHostingView *hostViewDewPoint;

@property (nonatomic, strong) CPTGraph *graphTemperature;
@property (nonatomic, strong) CPTGraph *graphHumidity;
@property (nonatomic, strong) CPTGraph *graphDewPoint;

@property (nonatomic, strong) CPTScatterPlot *plotTemperature;
@property (nonatomic, strong) CPTScatterPlot *plotHumidity;
@property (nonatomic, strong) CPTScatterPlot *plotDewPoint;

@property (nonatomic, assign) TempoReadingType currentReadingType;
@property (strong, nonatomic) IBOutlet UIButton *buttonAll;
@property (strong, nonatomic) IBOutlet UILabel *labelUnit;

@property (nonatomic, weak) CPTGraph *activeGraph;
@property (nonatomic, weak) UIView *activeGraphView;

/**
 *	Properties used for graph zooming
 **/
@property (nonatomic, assign) double initialLengthX;
@property (nonatomic, assign) double initialLengthY;

@end

@implementation TDGraphViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	[self changeReadingType:TempoReadingTypeTemperature];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self setupView];
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

- (void)setupView {
	[super setupView];
	[_buttonAll setBackgroundImage:[[_buttonAll backgroundImageForState:UIControlStateNormal] copy] forState:UIControlStateSelected];
	[self initPlot];
	[self adjustPlotsRange];
}

- (void)changeReadingType:(TempoReadingType)type {
	switch (type) {
  case TempoReadingTypeTemperature:
			if (!_viewGraphTemperature) {
				_viewGraphTemperature = _viewGraphHumidity ? _viewGraphHumidity : _viewGraphDewPoint;
				_viewGraphHumidity = nil;
			}
		  [_labelReadingType setText:NSLocalizedString(@"TEMPERATURE", nil)];
		  _labelUnit.text = [TDDefaultDevice sharedDevice].selectedDevice.isFahrenheit.boolValue ? @"˚ FAHRENHEIT" : @"˚ CELSIUS";
			_activeGraph = _graphTemperature;
			_activeGraphView = _viewGraphTemperature;
			break;
			
		case TempoReadingTypeHumidity: {
			if (!_viewGraphHumidity) {
				_viewGraphHumidity = _viewGraphTemperature ? _viewGraphTemperature : _viewGraphDewPoint;
				_viewGraphTemperature = nil;
			}
			[_labelReadingType setText:NSLocalizedString(@"HUMIDITY", nil)];
			_labelUnit.text = @"% RELATIVE HUMIDITY";
			_activeGraph = _graphHumidity;
			_activeGraphView = _viewGraphHumidity;
			break;
		}
		case TempoReadingTypeDewPoint:
			if (!_viewGraphDewPoint) {
				_viewGraphDewPoint = _viewGraphTemperature ? _viewGraphTemperature : _viewGraphHumidity;
				_viewGraphTemperature = nil;
				_viewGraphHumidity = nil;
			}
			[_labelReadingType setText:NSLocalizedString(@"DEW POINT", nil)];
			_labelUnit.text = [TDDefaultDevice sharedDevice].selectedDevice.isFahrenheit.boolValue ? @"˚ FAHRENHEIT" : @"˚ CELSIUS";
			_activeGraph = _graphDewPoint;
			_activeGraphView = _viewGraphDewPoint;
			break;
			
  default:
			break;
	}
	_currentReadingType = type;
	[self initPlot];
	[self adjustPlotsRange];
}

- (void)handlePinch:(UIPinchGestureRecognizer*)sender
{
	UIView *plotView;
	CPTGraph *graph;
	switch (_currentReadingType) {
  case TempoReadingTypeTemperature:
			plotView = _viewGraphTemperature;
			graph = _graphTemperature;
			break;
		case TempoReadingTypeHumidity:
			plotView = _viewGraphHumidity;
			graph = _graphHumidity;
			break;
		case TempoReadingTypeDewPoint:
			plotView = _viewGraphDewPoint;
			graph = _graphDewPoint;
			break;
			
  default:
			break;
	}
	if (plotView && graph) {
		if (sender.state == UIGestureRecognizerStateBegan){
			
			CGPoint translation = [sender locationInView:plotView];
			NSLog(@"Start value %.2f %.2f", translation.x,translation.y );
			
			//remember start values which we will multiply
			
			CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace*)graph.defaultPlotSpace;
			_initialLengthX = plotSpace.xRange.lengthDouble;
			_initialLengthY = plotSpace.yRange.lengthDouble;
			return;
		}
		else if (sender.state == UIGestureRecognizerStateChanged){
			NSLog(@"Scale: %.2f", sender.scale);
			CGPoint pointFirst = [sender locationOfTouch:0 inView:plotView];
			CGPoint pointMiddle = [sender locationInView:plotView];
			NSLog(@"first: (%.2f,%.2f), second: (%.2f,%.2f)", pointFirst.x, pointFirst.y, pointMiddle.x, pointMiddle.y);
			
			/**
			 *	calculate angle between the fingers vector and y-axis (limit to values  0-90)
			 *	if the angle is below the vertical threshold only scale x axis.
			 *	if the angle is above horizontal threshold only scale y axis.
			 *	if the angle is between the treshold zoom both axis.
			 **/
			CGFloat deltaY = fabs(pointFirst.y - pointMiddle.y);
			CGFloat deltaX = fabs(pointFirst.x - pointMiddle.x);
			CGFloat angleInDegrees = fabs(fabs(atan2(deltaY, deltaX)*180/M_PI)-90);//-90 because Y-axis is at 90˚ to X-axis
			
			//limit to 1st quadrant
			if (angleInDegrees > 90)
			{
				angleInDegrees -= 90;
			}
			NSLog(@"Angle in degrees: %.2f",angleInDegrees);
			
			CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace*)graph.defaultPlotSpace;
			/*if (angleInDegrees < kTresholdZoomAngle) {
				 //zoom y
				 NSLog(@"Zoom Y");
				 plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:plotSpace.yRange.location length:@(fabs(_initialLengthY*(2.0-sender.scale)))];
			 }
			 else if (angleInDegrees > 90-kTresholdZoomAngle)
			 {*/
				//zoom x
				NSLog(@"Zoom X");
				plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:plotSpace.xRange.location length:@(fabs(_initialLengthX*(2.0-sender.scale)))];
			/*}
			 else
			 {
				 //adjust both
				 NSLog(@"Zooming both");
				 plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:plotSpace.xRange.location length:@(fabs(_initialLengthX*(2.0-sender.scale)))];
				 plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:plotSpace.yRange.location length:@(fabs(_initialLengthY*(2.0-sender.scale)))];
			 }*/
		}
	}
}

#pragma mark - Actions

- (IBAction)buttonChangeReadingTypeClicked:(UIButton *)sender {
	IBActionSheet *sheet = [[IBActionSheet alloc] initWithTitle:NSLocalizedString(@"Choose reading type", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Temperature", nil), NSLocalizedString(@"Humidity", nil), NSLocalizedString(@"Dew Point", nil), nil];
	[sheet setTitleTextColor:[UIColor blueMaestroBlue]];
	
	[sheet setButtonTextColor:[UIColor blueMaestroBlue]];
	
	[sheet setFont:[UIFont regularFontWithSize:15.0]];
	[sheet setTitleFont:[UIFont regularFontWithSize:12.0]];
	
	[sheet showInView:self.parentViewController.view];
	/*UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"READING TYPE", nil) message:NSLocalizedString(@"Choose reading type", nil) preferredStyle:UIAlertControllerStyleActionSheet];
	__weak typeof(self) weakself = self;
	[alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Temperature", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
		[weakself changeReadingType:TempoReadingTypeTemperature];
	}]];
	[alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Humidity", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
		[weakself changeReadingType:TempoReadingTypeHumidity];
	}]];
	[alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil]];
	[self presentViewController:alert animated:YES completion:nil];*/
}

- (IBAction)buttonDayClicked:(UIButton *)sender {
}

- (IBAction)buttonWeekClicked:(UIButton *)sender {
}

- (IBAction)buttonMonthClicked:(UIButton *)sender {
}

- (IBAction)buttonAllClicked:(UIButton *)sender {
	sender.selected = !sender.selected;
	[self changeReadingType:_currentReadingType];
}

#pragma mark - Graph setup

- (void)adjustPlotsRange {
	TempoDevice *device = [TDDefaultDevice sharedDevice].selectedDevice;
	/**
	 *	Adjust range for plot so that all points fit in the view with one hour before and after
	 **/
	CPTXYPlotSpace *plotSpaceTemperature = (CPTXYPlotSpace *)_graphTemperature.defaultPlotSpace;
	NSArray *readings = [[[TDDefaultDevice sharedDevice].selectedDevice readingsForType:@"Temperature"] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO]]];
	if (!_buttonAll.selected) {
		readings = [readings subarrayWithRange:NSMakeRange(0, MIN(readings.count, kInitialDataLoadCount))];
	}
	double lastReading = [[(Reading*)[readings firstObject] timestamp] timeIntervalSince1970];
	double firstReading = [[(Reading*)[readings lastObject] timestamp] timeIntervalSince1970];
	plotSpaceTemperature.xRange = [[CPTPlotRange alloc] initWithLocationDecimal:CPTDecimalFromFloat(firstReading-60*60) lengthDecimal:CPTDecimalFromFloat(MAX(60*60*2, lastReading-firstReading+60*60*2))];
	plotSpaceTemperature.yRange = [[CPTPlotRange alloc] initWithLocationDecimal:CPTDecimalFromFloat([TDHelper temperature:@(0.0) forDevice:device].floatValue) lengthDecimal:CPTDecimalFromFloat([TDHelper temperature:@(35.0) forDevice:device].floatValue)];
	
	CPTXYPlotSpace *plotSpaceHumidity = (CPTXYPlotSpace *)_graphHumidity.defaultPlotSpace;
	readings = [[[TDDefaultDevice sharedDevice].selectedDevice readingsForType:@"Humidity"] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO]]];
	if (!_buttonAll.selected) {
		readings = [readings subarrayWithRange:NSMakeRange(0, MIN(readings.count, kInitialDataLoadCount))];
	}
	lastReading = [[(Reading*)[readings firstObject] timestamp] timeIntervalSince1970];
	firstReading = [[(Reading*)[readings lastObject] timestamp] timeIntervalSince1970];
	plotSpaceHumidity.xRange = [[CPTPlotRange alloc] initWithLocationDecimal:CPTDecimalFromFloat(firstReading-60*60) lengthDecimal:CPTDecimalFromFloat(MAX(60*60*2, lastReading-firstReading+60*60*2))];
	plotSpaceHumidity.yRange = [[CPTPlotRange alloc] initWithLocationDecimal:CPTDecimalFromFloat(0.0) lengthDecimal:CPTDecimalFromFloat(100)];
	
	CPTXYPlotSpace *plotSpaceDewPoint = (CPTXYPlotSpace *)_graphDewPoint.defaultPlotSpace;
	readings = [[[TDDefaultDevice sharedDevice].selectedDevice readingsForType:@"DewPoint"] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO]]];
	if (!_buttonAll.selected) {
		readings = [readings subarrayWithRange:NSMakeRange(0, MIN(readings.count, kInitialDataLoadCount))];
	}
	lastReading = [[(Reading*)[readings firstObject] timestamp] timeIntervalSince1970];
	firstReading = [[(Reading*)[readings lastObject] timestamp] timeIntervalSince1970];
	plotSpaceDewPoint.xRange = [[CPTPlotRange alloc] initWithLocationDecimal:CPTDecimalFromFloat(firstReading-60*60) lengthDecimal:CPTDecimalFromFloat(MAX(60*60*2, lastReading-firstReading+60*60*2))];
	plotSpaceDewPoint.yRange = [[CPTPlotRange alloc] initWithLocationDecimal:CPTDecimalFromFloat([TDHelper temperature:@(0.0) forDevice:device].floatValue) lengthDecimal:CPTDecimalFromFloat([TDHelper temperature:@(35.0) forDevice:device].floatValue)];
}

-(void)initPlot
{
	if (_graphTemperature.superlayer) {
		[_graphTemperature removeFromSuperlayer];
	}
	if (_graphHumidity.superlayer) {
		[_graphHumidity removeFromSuperlayer];
	}
	if (_graphDewPoint.superlayer) {
		[_graphDewPoint removeFromSuperlayer];
	}
	if (_currentReadingType == TempoReadingTypeTemperature) {
		_hostViewTemperature = [self configureHost:_viewGraphTemperature forGraph:_hostViewTemperature];
		_graphTemperature = [self configureGraph:_graphTemperature hostView:_hostViewTemperature graphView:_viewGraphTemperature title:nil];
		_plotTemperature = [self configurePlot:_plotTemperature forGraph:_graphTemperature identifier:@"Temperature"];
		[self configureAxesForGraph:_graphTemperature plot:_plotTemperature];
	}
	else if (_currentReadingType == TempoReadingTypeHumidity) {
		_hostViewHumidity = [self configureHost:_viewGraphHumidity forGraph:_hostViewHumidity];
		_graphHumidity = [self configureGraph:_graphHumidity hostView:_hostViewHumidity graphView:_viewGraphHumidity title:nil];
		_plotHumidity = [self configurePlot:_plotHumidity forGraph:_graphHumidity identifier:@"Humidity"];
		[self configureAxesForGraph:_graphHumidity plot:_plotHumidity];
	}
	else if (_currentReadingType == TempoReadingTypeDewPoint) {
		_hostViewDewPoint = [self configureHost:_viewGraphDewPoint forGraph:_hostViewDewPoint];
		_graphDewPoint = [self configureGraph:_graphDewPoint hostView:_hostViewDewPoint graphView:_viewGraphDewPoint title:nil];
		_plotDewPoint = [self configurePlot:_plotDewPoint forGraph:_graphDewPoint identifier:@"DewPoint"];
		[self configureAxesForGraph:_graphDewPoint plot:_plotDewPoint];
	}
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
	
	UIPinchGestureRecognizer *pGes = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];
	[viewGraph addGestureRecognizer:pGes];
	
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
	for (id plot in graph.allPlots) {
		[graph removePlot:plot];
	}
	[graph addPlot:plot toPlotSpace:plotSpace];
	
	return plot;
}

- (void)configureAxesForGraph:(CPTGraph*)graph plot:(CPTScatterPlot*)plot
{
	// Set up axis.
	CPTXYAxisSet * axisSet = (CPTXYAxisSet *) graph.axisSet;
	
	axisSet.xAxis.labelingPolicy = CPTAxisLabelingPolicyEqualDivisions;//CPTAxisLabelingPolicyAutomatic
	axisSet.xAxis.preferredNumberOfMajorTicks = 6;
	axisSet.xAxis.minorTickLineStyle = nil;
	axisSet.xAxis.axisConstraints = [CPTConstraints constraintWithLowerOffset:0.0];
	
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat:@"dd MMM\nHH:mm"];
	CPTTimeFormatter *timeFormatter = [[CPTTimeFormatter alloc] initWithDateFormatter:formatter];
	timeFormatter.referenceDate = [NSDate dateWithTimeIntervalSince1970:0];
	[(CPTXYAxisSet *)graph.axisSet xAxis].labelFormatter = timeFormatter;
	
	axisSet.yAxis.labelingPolicy = CPTAxisLabelingPolicyAutomatic;
	//    axisSet.yAxis.preferredNumberOfMajorTicks = 6;
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
	minrangeLineStyle.lineColor = kColorGraphAverage;
	
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
	if ([plot.identifier isEqual:@"Temperature"]) {
		if (!_buttonAll.selected) {
			return MIN([[TDDefaultDevice sharedDevice].selectedDevice readingsForType:@"Temperature"].count, kInitialDataLoadCount);
		}
		else {
			return [[TDDefaultDevice sharedDevice].selectedDevice readingsForType:@"Temperature"].count;
		}
	}
	else if ([plot.identifier isEqual:@"Humidity"]) {
		if (!_buttonAll.selected) {
			return MIN([[TDDefaultDevice sharedDevice].selectedDevice readingsForType:@"Humidity"].count, kInitialDataLoadCount);
		}
		else {
			return [[TDDefaultDevice sharedDevice].selectedDevice readingsForType:@"Humidity"].count;
		}
	}
	else if ([plot.identifier isEqual:@"DewPoint"]) {
		if (!_buttonAll.selected) {
			return MIN([[TDDefaultDevice sharedDevice].selectedDevice readingsForType:@"DewPoint"].count, kInitialDataLoadCount);
		}
		else {
			return [[TDDefaultDevice sharedDevice].selectedDevice readingsForType:@"DewPoint"].count;
		}
	}
	else {
		return 0;
	}
}

- (NSNumber *) numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index
{
	NSArray *dataSource = @[];
	Reading *reading;
	if ([plot.identifier isEqual:@"Temperature"]) {
		dataSource = [[[TDDefaultDevice sharedDevice].selectedDevice readingsForType:@"Temperature"] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO]]];
	}
	else if ([plot.identifier isEqual:@"Humidity"]) {
		dataSource = [[[TDDefaultDevice sharedDevice].selectedDevice readingsForType:@"Humidity"] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO]]];
	}
	else if ([plot.identifier isEqual:@"DewPoint"]) {
		dataSource = [[[TDDefaultDevice sharedDevice].selectedDevice readingsForType:@"DewPoint"] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO]]];
	}
	reading = [dataSource objectAtIndex:index];
	
	switch (fieldEnum) {
		case CPTScatterPlotFieldX:
			if (fieldEnum == CPTScatterPlotFieldX)
			{
				return [NSNumber numberWithDouble:[reading.timestamp timeIntervalSince1970]];
			}
			break;
			
		case CPTScatterPlotFieldY:
			if ([plot.identifier isEqual:@"Humidity"]) {
				return reading.avgValue;
			}
			else {
				return [TDHelper temperature:reading.avgValue forDevice:[TDDefaultDevice sharedDevice].selectedDevice];
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

#pragma mark - CPTPlotSpaceDelegate

#pragma mark - IBActionSheetDelegate

- (void)actionSheet:(IBActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex != actionSheet.cancelButtonIndex) {
		if (buttonIndex == 0) {
			[self changeReadingType:TempoReadingTypeTemperature];
		}
		else if (buttonIndex == 1) {
			[self changeReadingType:TempoReadingTypeHumidity];
		}
		else if (buttonIndex == 2) {
			[self changeReadingType:TempoReadingTypeDewPoint];
		}
	}
}

@end
