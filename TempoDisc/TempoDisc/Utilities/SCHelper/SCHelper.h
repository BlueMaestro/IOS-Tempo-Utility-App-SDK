//
//  PBHelper.h
//  personalbestest
//
//  Created by Vladica Pesic on 31/03/2015.
//  Copyright (c) 2015 Vladica Pesic. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kTagSemiboldFont 4654
@import UIKit;

#ifdef DISTRIBUTION
#	define DLog(fmt, ...) //NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#else
#	define DLog(...)
#endif

// ALog always displays output regardless of the DEBUG setting
#define ALog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);


@interface SCHelper : NSObject

+ (BOOL)isNilOrEmpty:(NSString*)string;

+ (BOOL)stringIsValidEmail:(NSString *)checkString;

+ (BOOL)stringIsValidName:(NSString *)checkString;

+ (BOOL)stringIsValidAddress:(NSString *)checkString;

+ (UIImage *)imageWithColor:(UIColor *)color;

+ (UIImage *)imageWithColor:(UIColor *)color size:(CGSize)size;

+ (NSInteger)numberOfElementsInString:(NSString*)string;

+ (UITableViewCell*)cellForView:(UIView*)view;
+ (NSIndexPath*)indexPathForView:(UIView*)view inTableView:(UITableView*)tableView;

+ (UIImage *)convertImageToGrayScale:(UIImage *)image;

+ (UIImage*)scaledImageFromImage:(UIImage*)image;

+ (NSString*)formattedTimeLeftForDate:(NSDate*)postDate fromDate:(NSDate*)fromDate withFormatter:(NSNumberFormatter*)formatter;
+ (NSString*)formattedTimePassedForDate:(NSDate*)postDate fromDate:(NSDate*)date withFormatter:(NSNumberFormatter*)formatter;
+ (NSString*)formattedTimeLeftForDate:(NSDate*)postDate withFormatter:(NSNumberFormatter*)formatter;
+ (NSString*)formattedTimePassedForDate:(NSDate*)postDate withFormatter:(NSNumberFormatter*)formatter;

+ (void)adjustFontsForViews:(NSArray*)views;
+ (void)adjustConstantsForConstraints:(NSArray*)constraints;
+ (float)sizeModifier;

+ (BOOL)isValidEmail:(NSString *)checkString;

//1k, 1m...
+ (NSString*)formattedStringFromNumber:(NSNumber*)number withFormatter:(NSNumberFormatter*)formatter;
@end
