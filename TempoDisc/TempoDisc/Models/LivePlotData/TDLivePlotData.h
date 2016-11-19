//
//  TDLivePlotData.h
//  Tempo Utility
//
//  Created by Nikola Misic on 11/19/16.
//  Copyright © 2016 BlueMaestro. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TDLivePlotData : NSObject

@property (nonatomic, strong) NSNumber *temperature;
@property (nonatomic, strong) NSNumber *humidity;
@property (nonatomic, strong) NSNumber *dewPoint;
@property (nonatomic, strong) NSDate* timestamp;

- (id)initWithString:(NSString*)dataString;

- (id)initWithString:(NSString *)dataString timestamp:(NSDate*)pointDate;

+ (BOOL)isValidData:(NSString*)dataString;
@end
