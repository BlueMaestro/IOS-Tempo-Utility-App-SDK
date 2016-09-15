//
//  TDGraphViewController.m
//  TempoDisc
//
//  Created by Nikola Misic on 3/10/16.
//  Copyright © 2016 BlueMaestro. All rights reserved.
//

#import "TDGraphViewController.h"
#import <CorePlot/ios/CorePlot.h>

#define kGraphSymbolSize CGSizeMake(4,4)
#define kGraphSymbolSelectedSize 15
#define kGraphSymboldTouchArea 10.0
#define kColorGraphAverage [CPTColor colorWithComponentRed:157.0f/255.0f green:157.0f/255.0f blue:157.0f/255.0f alpha:1]
#define kColorGraphAxis [CPTColor colorWithComponentRed:17.0f/255.0f green:90.0f/255.0f blue:140.0f/255.0f alpha:1]
#define kFontGraphAxis @"Montserrat-Regular"
#define kGraphLineWidth 1
#define kGraphiPhoneFontSize 10
#define kGraphiPadFontSize 15
#define POPUP_TIME 5.0
#define GRAPH_LINE_TYPE CPTScatterPlotInterpolationCurved
//#define GRAPH_LINE_TYPE CPTScatterPlotInterpolationLinear

@interface TDGraphViewController () <CPTScatterPlotDataSource, CPTScatterPlotDelegate, CPTPlotSpaceDelegate>

@property (nonatomic, strong) CPTGraphHostingView *hostViewTemperature;
@property (nonatomic, strong) CPTGraphHostingView *hostViewHumidity;

@property (nonatomic, strong) CPTGraph *graphTemperature;
@property (nonatomic, strong) CPTGraph *graphHumidity;

@property (nonatomic, strong) CPTScatterPlot *plotTemperature;
@property (nonatomic, strong) CPTScatterPlot *plotHumidity;

@end

@implementation TDGraphViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
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
	[self initPlot];
	[self adjustPlotsRange];
	_viewGraphTemperature.layer.borderWidth = 1.0;
	_viewGraphTemperature.layer.borderColor = [UIColor buttonDarkGrey].CGColor;
}

- (void)changeReadingType:(TempoReadingType)type {
	switch (type) {
  case TempoReadingTypeTemperature: {
			  if (!_viewGraphTemperature) {
				  _viewGraphTemperature = _viewGraphHumidity;
				  _viewGraphHumidity = nil;
				  [_labelReadingType setText:NSLocalizedString(@"Temperature", nil)];
			  }
		
		}
			break;
			
		case TempoReadingTypeHumidity: {
			if (!_viewGraphHumidity) {
				_viewGraphHumidity = _viewGraphTemperature;
				_viewGraphTemperature = nil;
				[_labelReadingType setText:NSLocalizedString(@"Humidity", nil)];
			}
			break;
		}
			
  default:
			break;
	}
	[self initPlot];
	[self adjustPlotsRange];
}

#pragma mark - Actions

- (IBAction)buttonChangeReadingTypeClicked:(UIButton *)sender {
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"READING TYPE", nil) message:NSLocalizedString(@"Choose reading type", nil) preferredStyle:UIAlertControllerStyleActionSheet];
	__weak typeof(self) weakself = self;
	[alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Temperature", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
		[weakself changeReadingType:TempoReadingTypeTemperature];
	}]];
	[alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Humidity", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
		[weakself changeReadingType:TempoReadingTypeHumidity];
	}]];
	[alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil]];
	[self presentViewController:alert animated:YES completion:nil];
}

- (IBAction)buttonDayClicked:(UIButton *)sender {
}

- (IBAction)buttonWeekClicked:(UIButton *)sender {
}

- (IBAction)buttonMonthClicked:(UIButton *)sender {
}

- (IBAction)buttonAllClicked:(UIButton *)sender {
}

#pragma mark - Graph setup

- (void)adjustPlotsRange {
	/**
	 *	Adjust range for plot so that all points fit in the view with one hour before and after
	 **/
	CPTXYPlotSpace *plotSpaceTemperature = (CPTXYPlotSpace *)_graphTemperature.defaultPlotSpace;
	NSArray *readings = [[[TDDefaultDevice sharedDevice].selectedDevice readingsForType:@"Temperature"] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES]]];
	double firstReading = [[(Reading*)[readings firstObject] timestamp] timeIntervalSince1970];
	double lastReading = [[(Reading*)[readings lastObject] timestamp] timeIntervalSince1970];
	plotSpaceTemperature.xRange = [[CPTPlotRange alloc] initWithLocationDecimal:CPTDecimalFromFloat(firstReading-60*60) lengthDecimal:CPTDecimalFromFloat(MAX(60*60*2, lastReading-firstReading+60*60*2))];
	plotSpaceTemperature.yRange = [[CPTPlotRange alloc] initWithLocationDecimal:CPTDecimalFromFloat(0.0) lengthDecimal:CPTDecimalFromFloat(35.0)];
	
	CPTXYPlotSpace *plotSpaceHumidity = (CPTXYPlotSpace *)_graphHumidity.defaultPlotSpace;
	readings = [[[TDDefaultDevice sharedDevice].selectedDevice readingsForType:@"Humidity"] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES]]];
	firstReading = [[(Reading*)[readings firstObject] timestamp] timeIntervalSince1970];
	lastReading = [[(Reading*)[readings lastObject] timestamp] timeIntervalSince1970];
	plotSpaceHumidity.xRange = [[CPTPlotRange alloc] initWithLocationDecimal:CPTDecimalFromFloat(firstReading-60*60) lengthDecimal:CPTDecimalFromFloat(MAX(60*60*2, lastReading-firstReading+60*60*2))];
	plotSpaceHumidity.yRange = [[CPTPlotRange alloc] initWithLocationDecimal:CPTDecimalFromFloat(0.0) lengthDecimal:CPTDecimalFromFloat(100)];
}

-(void)initPlot
{
	if (_graphTemperature.superlayer) {
		[_graphTemperature removeFromSuperlayer];
	}
	if (_graphHumidity.superlayer) {
		[_graphHumidity removeFromSuperlayer];
	}
	_hostViewTemperature = [self configureHost:_viewGraphTemperature forGraph:_hostViewTemperature];
	_hostViewHumidity = [self configureHost:_viewGraphHumidity forGraph:_hostViewHumidity];
	
	_graphTemperature = [self configureGraph:_graphTemperature hostView:_hostViewTemperature graphView:_viewGraphTemperature title:nil];
	_graphHumidity = [self configureGraph:_graphHumidity hostView:_hostViewHumidity graphView:_viewGraphHumidity title:nil];
	
	_plotTemperature = [self configurePlot:_plotTemperature forGraph:_graphTemperature identifier:@"Temperature"];
	_plotHumidity = [self configurePlot:_plotHumidity forGraph:_graphHumidity identifier:@"Humidity"];
	
	[self configureAxesForGraph:_graphTemperature plot:_plotTemperature];
	[self configureAxesForGraph:_graphHumidity plot:_plotHumidity];
}

-(CPTGraphHostingView*)configureHost:(UIView*)graphView forGraph:(CPTGraphHostingView*)host
{
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
	[formatter setDateFormat:@"dd.MM\nHH:mm"];
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
		return [[TDDefaultDevice sharedDevice].selectedDevice readingsForType:@"Temperature"].count;
	}
	else if ([plot.identifier isEqual:@"Humidity"]) {
		return [[TDDefaultDevice sharedDevice].selectedDevice readingsForType:@"Humidity"].count;
	}
	else {
		return 0;
	}
}

- (NSNumber *) numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index
{
	NSArray *dataSource = @[];
	Reading *reading;
	if (plot == _plotTemperature) {
		dataSource = [[TDDefaultDevice sharedDevice].selectedDevice readingsForType:@"Temperature"];
	}
	else if (plot == _plotHumidity) {
		dataSource = [[TDDefaultDevice sharedDevice].selectedDevice readingsForType:@"Humidity"];
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
			return reading.avgValue;
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
@end
