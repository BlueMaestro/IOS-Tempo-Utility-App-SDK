//
//  LogMessage.h
//  TempoDisc
//
//  Created by Nikola Misic on 9/20/16.
//  Copyright © 2016 BlueMaestro. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum : NSInteger {
	LogMessageTypeOutbound = 0,
	LogMessageTypeInbound
} LogMessageType;

@interface LogMessage : NSObject

@property (nonatomic, strong) NSString *text;
@property (nonatomic, assign) LogMessageType type;

+ (LogMessage*)inboundMessage:(NSString*)message;
+ (LogMessage*)outboundMessage:(NSString*)message;
- (id)initWithMessage:(NSString*)message type:(LogMessageType)type;

@end
