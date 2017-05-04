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

#define kInitialDataLoadCount 24

#define kInitialReadingsLoad 30

@interface TDGraphViewController () <CPTScatterPlotDataSource, CPTScatterPlotDelegate, CPTPlotSpaceDelegate, IBActionSheetDelegate>

@property (nonatomic, strong) CPTGraphHostingView *hostViewTemperature;
@property (nonatomic, strong) CPTGraphHostingView *hostViewHumidity;
@property (nonatomic, strong) CPTGraphHostingView *hostViewDewPoint;
@property (nonatomic, strong) CPTGraphHostingView *hostViewCombinedTHD;

@property (nonatomic, strong) CPTGraph *graphTemperature;
@property (nonatomic, strong) CPTGraph *graphHumidity;
@property (nonatomic, strong) CPTGraph *graphDewPoint;
@property (nonatomic, strong) CPTGraph *graphCombinedTHD;

@property (nonatomic, strong) CPTScatterPlot *plotTemperature;
@property (nonatomic, strong) CPTScatterPlot *plotHumidity;
@property (nonatomic, strong) CPTScatterPlot *plotDewPoint;
@property (nonatomic, strong) CPTScatterPlot *plotCombinedTHD;

@property (nonatomic, assign) TempoReadingType currentReadingType;
@property (strong, nonatomic) IBOutlet UIButton *buttonAll;
@property (strong, nonatomic) IBOutlet UILabel *labelUnit;

@property (nonatomic, weak) CPTGraph *activeGraph;
@property (nonatomic, weak) UIView *activeGraphView;

@property (nonatomic, strong) UIView *viewAnnotationShowed;

/**
 *	Properties used for graph zooming
 **/
@property (nonatomic, assign) double initialLengthX;
@property (nonatomic, assign) double initialLengthY;

@property (nonatomic, strong) NSArray *temperatureData;
@property (nonatomic, strong) NSArray *humidityData;
@property (nonatomic, strong) NSArray *dewPointData;

@end

@implementation TDGraphViewController
{
    @private BOOL combinedGraph;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	
	combinedGraph = false;
	[self changeReadingType:TempoReadingTypeTemperature];
	
	[MBProgressHUD showHUDAddedTo:self.view animated:YES];
	__weak typeof(self) weakself = self;
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		weakself.temperatureData = [[[TDSharedDevice sharedDevice].selectedDevice readingsForType:@"Temperature"] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO]]];
		weakself.humidityData = [[[TDSharedDevice sharedDevice].selectedDevice readingsForType:@"Humidity"] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO]]];
		weakself.dewPointData = [[[TDSharedDevice sharedDevice].selectedDevice readingsForType:@"DewPoint"] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO]]];
		dispatch_async(dispatch_get_main_queue(), ^{
			[weakself changeReadingType:TempoReadingTypeTemperature];
			[MBProgressHUD hideHUDForView:weakself.view animated:NO];
		});
	});
	
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
    _labelReadingType.font = [UIFont fontWithName:@"Montserrat-Regular" size:18];
    _labelUnit.font = [UIFont fontWithName:@"Montserrat-Regular" size:12];
	switch (type) {
        case TempoReadingTypeTemperature:
            [_labelReadingType setText:NSLocalizedString(@"Temperature", nil)];
            _labelUnit.text = [TDSharedDevice sharedDevice].selectedDevice.isFahrenheit.boolValue ? @"º FAHRENHEIT" : @"º CELSIUS";
			_activeGraph = _graphTemperature;
			_activeGraphView = _viewGraphTemperature;
			break;
		case TempoReadingTypeHumidity:
            if (!_viewGraphHumidity) _viewGraphHumidity = _viewGraphTemperature;
			[_labelReadingType setText:NSLocalizedString(@"Humidity", nil)];
			_labelUnit.text = @"% RELATIVE HUMIDITY";
			_activeGraph = _graphHumidity;
			_activeGraphView = _viewGraphHumidity;
			break;
		case TempoReadingTypeDewPoint:
            if (!_viewGraphDewPoint) _viewGraphDewPoint = _viewGraphTemperature;
			[_labelReadingType setText:NSLocalizedString(@"Dew Point", nil)];
			_labelUnit.text = [TDSharedDevice sharedDevice].selectedDevice.isFahrenheit.boolValue ? @"º FAHRENHEIT" : @"º CELSIUS";
			_activeGraph = _graphDewPoint;
			_activeGraphView = _viewGraphDewPoint;
			break;
        default:
			break;
	}
    if (combinedGraph == true) {
        _labelUnit.text = [TDSharedDevice sharedDevice].selectedDevice.isFahrenheit.boolValue ? @"º FAHRENHEIT AND % RELATIVE HUMIDITY" : @"º CELSIUS AND % RELATIVE HUMIDITY";
        if (!_viewGraphCombinedTHD) _viewGraphCombinedTHD = _viewGraphTemperature;
        [_labelReadingType setText:NSLocalizedString(@"Combined Graph", nil)];
        _activeGraph = _graphCombinedTHD;
        _activeGraphView = _viewGraphCombinedTHD;
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
    if (combinedGraph == true) {
        plotView = _viewGraphCombinedTHD;
        graph = _graphCombinedTHD;
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
			if (angleInDegrees < kTresholdZoomAngle) {
				 //zoom y
				 NSLog(@"Zoom Y");
				 plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:plotSpace.yRange.location length:@(fabs(_initialLengthY*(2.0-sender.scale)))];
			 }
			 else if (angleInDegrees > 90-kTresholdZoomAngle)
			 {
				//zoom x
				NSLog(@"Zoom X");
				plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:plotSpace.xRange.location length:@(fabs(_initialLengthX*(2.0-sender.scale)))];
			}
			 else
			 {
				 //adjust both
				 NSLog(@"Zooming both");
				 plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:plotSpace.xRange.location length:@(fabs(_initialLengthX*(2.0-sender.scale)))];
				 plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:plotSpace.yRange.location length:@(fabs(_initialLengthY*(2.0-sender.scale)))];
			 }
		}
	}
}

#pragma mark - Actions

- (IBAction)buttonChangeReadingTypeClicked:(UIButton *)sender {
	IBActionSheet *sheet = [[IBActionSheet alloc] initWithTitle:NSLocalizedString(@"Choose reading type", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Temperature", nil), NSLocalizedString(@"Humidity", nil), NSLocalizedString(@"Dew Point", nil), NSLocalizedString(@"Combined", nil), nil];
	[sheet setTitleTextColor:[UIColor blueMaestroBlue]];
	
	[sheet setButtonTextColor:[UIColor blueMaestroBlue]];
	
	[sheet setFont:[UIFont regularFontWithSize:18.0]];
	[sheet setTitleFont:[UIFont regularFontWithSize:15.0]];
	
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
	if (_temperatureData.count == 0) {
		return;
	}
    NSArray *readings = @[];
	TempoDevice *device = [TDSharedDevice sharedDevice].selectedDevice;
	/**
	 *	Adjust range for plot so that all points fit in the view with one hour before and after
	 **/
	CPTXYPlotSpace *plotSpaceTemperature = (CPTXYPlotSpace *)_graphTemperature.defaultPlotSpace;
	readings = _temperatureData;
	if (!_buttonAll.selected) {
		readings = [readings subarrayWithRange:NSMakeRange(0, MIN(readings.count, kInitialDataLoadCount))];
	}
	double lastReading = [[(Reading*)readings[readings.count - MIN(readings.count, kInitialReadingsLoad)] timestamp] timeIntervalSince1970];
	double firstReading = [[(Reading*)[readings lastObject] timestamp] timeIntervalSince1970];
	plotSpaceTemperature.xRange = [[CPTPlotRange alloc] initWithLocationDecimal:CPTDecimalFromFloat(firstReading-60*60) lengthDecimal:CPTDecimalFromFloat(MAX(60*60*2, lastReading-firstReading+60*60*2))];
	plotSpaceTemperature.yRange = [[CPTPlotRange alloc] initWithLocationDecimal:CPTDecimalFromFloat([TDHelper temperature:@(0.0) forDevice:device].floatValue) lengthDecimal:CPTDecimalFromFloat([TDHelper temperature:@(35.0) forDevice:device].floatValue)];
        
	CPTXYPlotSpace *plotSpaceHumidity = (CPTXYPlotSpace *)_graphHumidity.defaultPlotSpace;
	readings = _humidityData;
	if (!_buttonAll.selected) {
		readings = [readings subarrayWithRange:NSMakeRange(0, MIN(readings.count, kInitialDataLoadCount))];
	}
	lastReading = [[(Reading*)readings[readings.count - MIN(readings.count, kInitialReadingsLoad)] timestamp] timeIntervalSince1970];
	firstReading = [[(Reading*)[readings lastObject] timestamp] timeIntervalSince1970];
	plotSpaceHumidity.xRange = [[CPTPlotRange alloc] initWithLocationDecimal:CPTDecimalFromFloat(firstReading-60*60) lengthDecimal:CPTDecimalFromFloat(MAX(60*60*2, lastReading-firstReading+60*60*2))];
	plotSpaceHumidity.yRange = [[CPTPlotRange alloc] initWithLocationDecimal:CPTDecimalFromFloat(0.0) lengthDecimal:CPTDecimalFromFloat(100)];
	
	CPTXYPlotSpace *plotSpaceDewPoint = (CPTXYPlotSpace *)_graphDewPoint.defaultPlotSpace;
	readings = _dewPointData;
	if (!_buttonAll.selected) {
		readings = [readings subarrayWithRange:NSMakeRange(0, MIN(readings.count, kInitialDataLoadCount))];
	}
	lastReading = [[(Reading*)readings[readings.count - MIN(readings.count, kInitialReadingsLoad)] timestamp] timeIntervalSince1970];
	firstReading = [[(Reading*)[readings lastObject] timestamp] timeIntervalSince1970];
	plotSpaceDewPoint.xRange = [[CPTPlotRange alloc] initWithLocationDecimal:CPTDecimalFromFloat(firstReading-60*60) lengthDecimal:CPTDecimalFromFloat(MAX(60*60*2, lastReading-firstReading+60*60*2))];
	plotSpaceDewPoint.yRange = [[CPTPlotRange alloc] initWithLocationDecimal:CPTDecimalFromFloat([TDHelper temperature:@(0.0) forDevice:device].floatValue) lengthDecimal:CPTDecimalFromFloat([TDHelper temperature:@(35.0) forDevice:device].floatValue)];
    
    if (combinedGraph == true){
        
        CPTXYPlotSpace *plotSpaceDewPoint = (CPTXYPlotSpace *)_graphCombinedTHD.defaultPlotSpace;
		readings = _dewPointData;
        readings = [readings subarrayWithRange:NSMakeRange(0, MIN(readings.count, kInitialDataLoadCount))];
        lastReading = [[(Reading*)readings[readings.count - MIN(readings.count, kInitialReadingsLoad)] timestamp] timeIntervalSince1970];
        firstReading = [[(Reading*)[readings lastObject] timestamp] timeIntervalSince1970];
        plotSpaceDewPoint.xRange = [[CPTPlotRange alloc] initWithLocationDecimal:CPTDecimalFromFloat(firstReading-60*60) lengthDecimal:CPTDecimalFromFloat(MAX(60*60*2, lastReading-firstReading+60*60*2))];
        plotSpaceDewPoint.yRange = [[CPTPlotRange alloc] initWithLocationDecimal:CPTDecimalFromFloat([TDHelper temperature:@(0.0) forDevice:device].floatValue) lengthDecimal:CPTDecimalFromFloat([TDHelper temperature:@(35.0) forDevice:device].floatValue)];
        
        CPTXYPlotSpace *plotSpaceHumidity = (CPTXYPlotSpace *)_graphCombinedTHD.defaultPlotSpace;
		readings = _humidityData;
        if (!_buttonAll.selected) {
            readings = [readings subarrayWithRange:NSMakeRange(0, MIN(readings.count, kInitialDataLoadCount))];
        }
        lastReading = [[(Reading*)readings[readings.count - MIN(readings.count, kInitialReadingsLoad)] timestamp] timeIntervalSince1970];
        firstReading = [[(Reading*)[readings lastObject] timestamp] timeIntervalSince1970];
        plotSpaceHumidity.xRange = [[CPTPlotRange alloc] initWithLocationDecimal:CPTDecimalFromFloat(firstReading-60*60) lengthDecimal:CPTDecimalFromFloat(MAX(60*60*2, lastReading-firstReading+60*60*2))];
        plotSpaceHumidity.yRange = [[CPTPlotRange alloc] initWithLocationDecimal:CPTDecimalFromFloat(0.0) lengthDecimal:CPTDecimalFromFloat(100)];
        
        
    }
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
    if (_graphCombinedTHD.superlayer) {
        [_graphCombinedTHD removeFromSuperlayer];
    }
    
    if (combinedGraph == true) {
        _hostViewCombinedTHD = [self configureHost:_viewGraphCombinedTHD forGraph:_hostViewCombinedTHD];
        _graphCombinedTHD = [self configureGraph:_graphCombinedTHD hostView:_hostViewCombinedTHD graphView:_viewGraphCombinedTHD title:nil];
        _plotHumidity = [self configurePlot:_plotHumidity forGraph:_graphCombinedTHD identifier:@"Humidity"];
        [self configureAxesForGraph:_graphCombinedTHD plot:_plotHumidity];
        _plotTemperature = [self configurePlot:_plotTemperature forGraph:_graphCombinedTHD identifier:@"Temperature"];
        [self configureAxesForGraph:_graphCombinedTHD plot:_plotTemperature];
        _plotDewPoint = [self configurePlot:_plotDewPoint forGraph:_graphCombinedTHD identifier:@"DewPoint"];
        [self configureAxesForGraph:_graphCombinedTHD plot:_plotDewPoint];
        return;
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
	host = [(CPTGraphHostingView *)[CPTGraphHostingView alloc] initWithFrame:CGRectInset(graphView.bounds, 5, 6)];
	host.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    
	[graphView addSubview:host];
	return host;
}

- (CPTGraph*)configureGraph:(CPTGraph*)graph hostView:(CPTGraphHostingView*)hostView graphView:(UIView*)viewGraph title:(NSString*)title
{
	// 1 - Create the graph
	graph = [[CPTXYGraph alloc] initWithFrame:CGRectInset(viewGraph.bounds, 5, 5)];
	graph.title = title;
	graph.titleDisplacement = CGPointMake(0, 15.0);
	hostView.hostedGraph = graph;
	//	_graph.plotAreaFrame.plotArea.delegate = self;
	
	// Set up the look of the plot. Want
	[graph applyTheme:[CPTTheme themeNamed:kCPTSlateTheme]];
	
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
    NSNumber *range = [NSNumber numberWithInt:(10)];
    NSNumber *start = [NSNumber numberWithInt:(0)];
    plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:start length:range];

	
	// Set up the plot, including the look of the plot itself.
	plot = [self plotWithIdentifier:identifier];
    /*
	for (id plot in graph.allPlots) {
		//[graph removePlot:plot];
	}
     */

    [graph addPlot:plot toPlotSpace:plotSpace];

	return plot;
}

- (void)configureAxesForGraph:(CPTGraph*)graph plot:(CPTScatterPlot*)plot
{
    // Need to add the ability to plot two or three graphs
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
	majorGridLineStyle.lineWidth = 0.8;
	
	CPTMutableLineStyle *minorGridLineStyle = [CPTMutableLineStyle lineStyle];
	minorGridLineStyle.lineColor = [CPTColor colorWithGenericGray:0.8];
	minorGridLineStyle.lineWidth = 0.5;
	
	CPTMutableLineStyle *tickLineStyle = [CPTMutableLineStyle lineStyle];
	tickLineStyle.lineColor = [CPTColor colorWithGenericGray:0.1];
	tickLineStyle.lineWidth = 0.5;
    
    CPTMutableLineStyle *axisLineStyle = [CPTMutableLineStyle lineStyle];
    axisLineStyle.lineColor = [CPTColor colorWithGenericGray:0.5];
    axisLineStyle.lineWidth = 4.0;
	
	axisSet.yAxis.minorTickLineStyle = tickLineStyle;
    axisSet.yAxis.axisLineStyle = axisLineStyle;
	axisSet.yAxis.majorGridLineStyle = majorGridLineStyle;
	axisSet.yAxis.minorGridLineStyle = minorGridLineStyle;
    axisSet.xAxis.axisLineStyle = axisLineStyle;
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
	

	CPTMutableLineStyle *minrangeLineStyle = [plot.dataLineStyle mutableCopy];
	CPTMutableLineStyle *newSymbolLineStyle = [CPTMutableLineStyle lineStyle];
    CPTPlotSymbol *temperatureSymbol = [CPTPlotSymbol ellipsePlotSymbol];
    
    newSymbolLineStyle.lineColor = kColorGraphAverage;
    minrangeLineStyle.lineColor = kColorGraphAverage;
    temperatureSymbol.fill = [CPTFill fillWithColor:kColorGraphAverage];
    
    if (combinedGraph == true) {
        if (plot == _plotTemperature) {
            newSymbolLineStyle.lineColor=kColorGraphTemperature;
            minrangeLineStyle.lineColor=kColorGraphTemperature;
            temperatureSymbol.fill = [CPTFill fillWithColor:kColorGraphTemperature];
        }
        if (plot == _plotDewPoint) {
            newSymbolLineStyle.lineColor=kColorGraphDewPoint;
            minrangeLineStyle.lineColor=kColorGraphDewPoint;
            temperatureSymbol.fill = [CPTFill fillWithColor:kColorGraphDewPoint];
        }
    }
    newSymbolLineStyle.lineWidth = kGraphLineWidth;
    minrangeLineStyle.lineWidth = kGraphLineWidth;
    
    plot.dataLineStyle=minrangeLineStyle;
    plot.interpolation=GRAPH_LINE_TYPE;
	
	temperatureSymbol.size=kGraphSymbolSize;
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
		/*if (!_buttonAll.selected) {
			return MIN([[TDSharedDevice sharedDevice].selectedDevice readingsForType:@"Temperature"].count, kInitialDataLoadCount);
		}
		else {*/
			return _temperatureData.count;
		/*}*/
	}
	else if ([plot.identifier isEqual:@"Humidity"]) {
		/*if (!_buttonAll.selected) {
			return MIN([[TDSharedDevice sharedDevice].selectedDevice readingsForType:@"Humidity"].count, kInitialDataLoadCount);
		}
		else { */
			return _humidityData.count;
		/*}*/
	}
	else if ([plot.identifier isEqual:@"DewPoint"]) {
		/*if (!_buttonAll.selected) {
			return MIN([[TDSharedDevice sharedDevice].selectedDevice readingsForType:@"DewPoint"].count, kInitialDataLoadCount);
		}
		else { */
			return _dewPointData.count;
		/*}*/
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
		dataSource = _temperatureData;
	}
	else if ([plot.identifier isEqual:@"Humidity"]) {
		dataSource = _humidityData;
	}
	else if ([plot.identifier isEqual:@"DewPoint"]) {
		dataSource = _dewPointData;
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
				return [TDHelper temperature:reading.avgValue forDevice:[TDSharedDevice sharedDevice].selectedDevice];
			}
			
			break;
	}
	return [NSNumber numberWithFloat:0.0];
}

#pragma mark - CPTScatterPlotDelegate

- (CPTPlotSymbol *)symbolForScatterPlot:(CPTScatterPlot *)plot recordIndex:(NSUInteger)idx {
	CPTPlotSymbol *temperatureSymbol = [CPTPlotSymbol ellipsePlotSymbol];
    CPTMutableLineStyle *minrangeLineStyle = [plot.dataLineStyle mutableCopy];
    minrangeLineStyle.lineWidth = kGraphLineWidth;
    minrangeLineStyle.lineColor = kColorGraphAverage;
    if (combinedGraph == true){
        if (plot == _plotDewPoint) {
            minrangeLineStyle.lineColor = kColorGraphDewPoint;
        }
        if (plot == _plotTemperature) {
            minrangeLineStyle.lineColor = kColorGraphTemperature;
        }
    }
    temperatureSymbol.size=kGraphSymbolSize;
    temperatureSymbol.fill=[CPTFill fillWithColor:[CPTColor whiteColor]];
    temperatureSymbol.lineStyle = minrangeLineStyle;
	return temperatureSymbol;
}

#pragma mark - CPTPlotSpaceDelegate

-(void)scatterPlot:(CPTPlot *)plot
plotSymbolWasSelectedAtRecordIndex:(NSUInteger)index withEvent:(nonnull CPTNativeEvent *)event
{
    Reading *reading;
	NSArray *dataSource = @[];
    NSString *valueSymbol;
	NSNumber *value = @0;//reading value

	UIView *viewGraph;
    if ([plot.identifier isEqual:@"Temperature"]) {
		dataSource = _temperatureData;
        valueSymbol = @"º";
        if (combinedGraph) {
            viewGraph = _viewGraphCombinedTHD;
        } else {
            viewGraph = _viewGraphTemperature;
        }
		reading = [dataSource objectAtIndex:index];
		value = [TDHelper temperature:reading.avgValue forDevice:[TDSharedDevice sharedDevice].selectedDevice];
	}
    else if ([plot.identifier isEqual:@"Humidity"]) {
		dataSource = _humidityData;
        valueSymbol = @"% RH";
        if (combinedGraph) {
            viewGraph = _viewGraphCombinedTHD;
        } else {
            viewGraph = _viewGraphHumidity;
        }
		reading = [dataSource objectAtIndex:index];
		value = reading.avgValue;
    }
    else if ([plot.identifier isEqual:@"DewPoint"]) {
		dataSource = _dewPointData;
        valueSymbol = @"º";
        if (combinedGraph) {
            viewGraph = _viewGraphCombinedTHD;
        } else {
            viewGraph = _viewGraphDewPoint;
        }
		reading = [dataSource objectAtIndex:index];
		value = [TDHelper temperature:reading.avgValue forDevice:[TDSharedDevice sharedDevice].selectedDevice];
    }
	
	
	
	NSDate *timestamp = reading.timestamp;//reading date
	
	NSLog(@"Value at index %@ with timestamp of %@", value, timestamp);
    
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"dd-MMM"];
    
    NSDateFormatter *timeFormat = [[NSDateFormatter alloc] init];
    [timeFormat setDateFormat:@"HH:mm"];
    
    NSString *timeFromTimestamp = [timeFormat stringFromDate:timestamp];
    NSString *dateFromTimestamp = [dateFormat stringFromDate:timestamp];

    // Setup a style for the annotation
    CPTMutableTextStyle *hitAnnotationTextStyle = [CPTMutableTextStyle textStyle];
    hitAnnotationTextStyle.color = [CPTColor grayColor];
    hitAnnotationTextStyle.fontSize = 13.0f;
    hitAnnotationTextStyle.fontName = @"Helvetica-Bold";
	
	CGPoint point = [[[[event allTouches] allObjects] firstObject] locationInView:viewGraph];
//    CGPoint point = [value CGPointValue];
    //CGPoint point = [[[[event allTouches] allObjects] firstObject] locationInView:plot.graph.hostingView];
    
    // Determine point of symbol in plot coordinates
    NSNumber *x = [NSNumber numberWithFloat:point.x+plot.frame.origin.x];
    NSNumber *y = [NSNumber numberWithFloat:point.y+plot.frame.origin.y];
    NSArray *anchorPoint = [NSArray arrayWithObjects:x, y, nil];
    
    // First make a string for the y value
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setMaximumFractionDigits:2];
    NSString *yString = [formatter stringFromNumber:value];
    NSString *yStringWithSymbol = [NSString stringWithFormat:@"%@%@", yString, valueSymbol];
    
    // Now add the annotation to the plot area
    CPTTextLayer *textLayer = [[CPTTextLayer alloc] initWithText:yString style:hitAnnotationTextStyle];
    CPTPlotSpaceAnnotation *symbolTextAnnotation;
    symbolTextAnnotation = [[CPTPlotSpaceAnnotation alloc] initWithPlotSpace:plot.plotSpace  anchorPlotPoint:anchorPoint];
    symbolTextAnnotation.contentLayer = textLayer;
    symbolTextAnnotation.displacement = CGPointMake(0.0f, 20.0f);

//    [plot addAnnotation:symbolTextAnnotation];
	
	
	[_viewAnnotationShowed removeFromSuperview];
	//create view to host the label info
	float width = [yString sizeWithAttributes:@{NSFontAttributeName : [UIFont systemFontOfSize:12]}].width;//text width
	//point is the graph symbol location, adjust view frame as needed
	UIView *viewHostLabel = [[UIView alloc] initWithFrame:CGRectMake(point.x, point.y-80, width+50, 70)];//30pts padding, fixed 35pts height
    viewHostLabel.layer.cornerRadius = 8.0;
    viewHostLabel.clipsToBounds = true;
	viewHostLabel.backgroundColor = [UIColor blueMaestroBlue];
    if (combinedGraph) {
        if ([plot.identifier isEqual:@"DewPoint"]) {
            viewHostLabel.backgroundColor = [UIColor graphDewPoint];
        }
        if ([plot.identifier isEqual:@"Temperature"]) {
            viewHostLabel.backgroundColor = [UIColor graphTemperature];
        }
    }
    
	
	//add label withing the host view
	UILabel *labelAnnotation = [[UILabel alloc] initWithFrame:viewHostLabel.bounds];
    labelAnnotation.numberOfLines = 0;
    NSString *labelString = [NSString stringWithFormat:@"%@ \r %@ \r %@", yStringWithSymbol, timeFromTimestamp, dateFromTimestamp];
    //NSString *labelString = @"%@\n%@", yString, timestamp;
    [labelAnnotation setFont:[UIFont fontWithName:@"Montserrat-Regular" size:13.0]];
    labelAnnotation.text = labelString;
	labelAnnotation.textAlignment = NSTextAlignmentCenter;
	labelAnnotation.textColor = [UIColor whiteColor];
	[viewHostLabel addSubview:labelAnnotation];
	
	[viewGraph addSubview:viewHostLabel];
	
	//auto remove after 5s
	[viewHostLabel performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:5.0];
    _viewAnnotationShowed = viewHostLabel;
}

- (void)plotSpace:(CPTPlotSpace *)space didChangePlotRangeForCoordinate:(CPTCoordinate)coordinate {
	[_viewAnnotationShowed removeFromSuperview];
//    [graph.plotAreaFrame.plotArea addAnnotation:symbolTextAnnotation];
	
}
    

#pragma mark - IBActionSheetDelegate

- (void)actionSheet:(IBActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex != actionSheet.cancelButtonIndex) {
        combinedGraph = false;
		if (buttonIndex == 0) {
			[self changeReadingType:TempoReadingTypeTemperature];
		}
		else if (buttonIndex == 1) {
			[self changeReadingType:TempoReadingTypeHumidity];
		}
		else if (buttonIndex == 2) {
			[self changeReadingType:TempoReadingTypeDewPoint];
		}
        else if (buttonIndex == 3) {
            combinedGraph = true;
            [self changeReadingType:TempoReadingTypeTemperature];
        }
	}
}

@end
