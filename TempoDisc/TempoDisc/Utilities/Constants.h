//
//  Constants.h
//  TempoDisc
//
//  Created by Nikola Misic on 3/14/16.
//  Copyright © 2016 BlueMaestro. All rights reserved.
//

#ifndef Constants_h
#define Constants_h

#define kNotificationPeripheralUpdated @"kNotificationPeripheralUpdated"
#define kKeyNotificationPeripheralUpdatedPeripheral @"kNotificationPeripheralUpdated"

#pragma mark - Graph constants

#define kLivePlotInitiateString @"*bur"
#define kLivePlotPaddingInSeconds	15.
#define kLivePlotWindowInSeconds	20.
#define kLivePlotMinXAxisValue		0.
#define kLivePlotMaxXAxisValue		120.
#define kColorLivePlotLineTemperature [UIColor redColor]
#define kColorLivePlotLineHumidty [UIColor blueColor]
#define kColorLivePlotLineDewPoint [UIColor greenColor]

#define kGraphSymbolSize CGSizeMake(4,4)
#define kGraphSymbolSelectedSize 15
#define kGraphSymboldTouchArea 10.0
#define kColorGraphAverage [CPTColor colorWithComponentRed:7/255.0f green:119/255.0f blue:190/255.0f alpha:1]
#define kColorGraphAxis [CPTColor colorWithComponentRed:17.0f/255.0f green:90.0f/255.0f blue:140.0f/255.0f alpha:1]
#define kColorGraphHumidity [CPTColor colorWithComponentRed:7/255.0f green:119/255.0f blue:190/255.0f alpha:1]
#define kColorGraphTemperature [CPTColor colorWithComponentRed:208/255.0f green:3/255.0f blue:3/255.0f alpha:1]
#define kColorGraphDewPoint [CPTColor colorWithComponentRed:13/255.0f green:204/255.0f blue:80/255.0f alpha:1]
#define kFontGraphAxis @"Montserrat-Regular"
#define kGraphLineWidth 2
#define kGraphiPhoneFontSize 14
#define kGraphiPadFontSize 20
#define POPUP_TIME 5.0
#define GRAPH_LINE_TYPE CPTScatterPlotInterpolationCurved
//#define GRAPH_LINE_TYPE CPTScatterPlotInterpolationLinear

#endif /* Constants_h */
