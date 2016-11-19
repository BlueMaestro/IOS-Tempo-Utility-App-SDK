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

@interface TDLivePlotViewController () <CPTScatterPlotDataSource, CPTScatterPlotDelegate, CPTPlotSpaceDelegate>

@property (strong, nonatomic) IBOutlet UIView *viewPlotContainer;

@property (nonatomic, strong) CPTGraphHostingView *hostView;

@property (nonatomic, strong) CPTGraph *graph;

@property (nonatomic, strong) CPTScatterPlot *plotTemperature;
@property (nonatomic, strong) CPTScatterPlot *plotHumidity;
@property (nonatomic, strong) CPTScatterPlot *plotDewPoint;

@property (nonatomic, strong) NSArray* dataSource;

@end

@implementation TDLivePlotViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	NSDate *rightNow = [NSDate date];
	NSMutableArray *mockedData = [@[] mutableCopy];
	for (NSInteger i=0; i<30; i++) {
		TDLivePlotData *data = [[TDLivePlotData alloc] initWithString:@"T25.4H56.7D16.8" timestamp:[rightNow dateByAddingTimeInterval:i]];
		[mockedData addObject:data];
	}
	
	_dataSource = mockedData;
	[self initPlot];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self adjustPlotsRange];
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

#pragma mark - Graph setup

- (void)adjustPlotsRange {
//	TempoDevice *device = [TDDefaultDevice sharedDevice].selectedDevice;
	/**
	 *	Adjust range for plot so that the last point is in the center with a few seconds to the left and right of the x axis
	 **/
	CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)_graph.defaultPlotSpace;
	TDLivePlotData *lastData = [_dataSource lastObject];
	
	plotSpace.xRange = [[CPTPlotRange alloc] initWithLocationDecimal:CPTDecimalFromFloat(lastData.timestamp.timeIntervalSince1970-kLivePlotPaddingInSeconds) lengthDecimal:CPTDecimalFromFloat(kLivePlotWindowInSeconds)];
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
	axisSet.yAxis.preferredNumberOfMajorTicks = 5;
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
