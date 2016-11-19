//
//  TDLivePlotData.m
//  Tempo Utility
//
//  Created by Nikola Misic on 11/19/16.
//  Copyright © 2016 BlueMaestro. All rights reserved.
//

#import "TDLivePlotData.h"

@implementation TDLivePlotData

- (id)initWithString:(NSString *)dataString {
	if (self = [super init]) {
		
	}
	
	return self;
}

- (id)initWithString:(NSString *)dataString timestamp:(NSDate *)pointDate {
	self = [[TDLivePlotData alloc] initWithString:dataString];
	_timestamp = pointDate;
	return self;
}

@end
