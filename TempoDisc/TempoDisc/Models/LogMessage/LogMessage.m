//
//  LogMessage.m
//  TempoDisc
//
//  Created by Nikola Misic on 9/20/16.
//  Copyright © 2016 BlueMaestro. All rights reserved.
//

#import "LogMessage.h"

@implementation LogMessage

- (id)initWithMessage:(NSString *)message type:(LogMessageType)type {
	if (self = [super init]) {
		self.text = message;
		self.type = type;
	}
	return self;
}

+ (LogMessage *)inboundMessage:(NSString *)message {
	return [[LogMessage alloc] initWithMessage:message type:LogMessageTypeInbound];
}

+ (LogMessage *)outboundMessage:(NSString *)message {
	return [[LogMessage alloc] initWithMessage:message type:LogMessageTypeOutbound];
}

@end
