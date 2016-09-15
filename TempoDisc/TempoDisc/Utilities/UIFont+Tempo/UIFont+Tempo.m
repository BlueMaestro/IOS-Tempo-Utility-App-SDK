//
//  UIFont+Tempo.m
//  TempoDisc
//
//  Created by Nikola Misic on 9/15/16.
//  Copyright © 2016 BlueMaestro. All rights reserved.
//

#import "UIFont+Tempo.h"

@implementation UIFont (Tempo)

+ (UIFont *)regularFontWithSize:(CGFloat)size {
	return [UIFont fontWithName:@"Montserrat-Regular" size:size];
}

+ (UIFont *)boldFontWithSize:(CGFloat)size {
	return [UIFont fontWithName:@"Montserrat-Bold" size:size];
}

@end
