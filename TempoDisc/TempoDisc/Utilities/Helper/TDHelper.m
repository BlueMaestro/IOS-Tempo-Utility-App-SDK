//
//  TDHelper.m
//  TempoDisc
//
//  Created by Nikola Misic on 2/28/16.
//  Copyright © 2016 BlueMaestro. All rights reserved.
//

#import "TDHelper.h"
#import <LGBluetooth/LGBluetooth.h>

@implementation TDHelper


+ (NSNumber *)temperature:(NSNumber *)temp forDevice:(TempoDevice *)device
{
	return device.isFahrenheit.boolValue ? [NSNumber numberWithDouble:temp.doubleValue*1.8+32] : temp;
}


/**
 *	Provided code for TempoDisc
 **/
- (void) writeAndRead:(int16_t)dataToWrite peripheral:(LGPeripheral *)peripheral {
	
	NSMutableArray *tempArrayFloat = [NSMutableArray array];
	NSMutableArray *tempArrayBytes = [NSMutableArray array];
	NSMutableArray *humArrayFloat = [NSMutableArray array];
	NSMutableArray *humArrayBytes = [NSMutableArray array];
	NSDate *maxDate;
	NSInteger indexDownload = 0;
	NSDate *nowDate;
	NSManagedObjectContext *managedObjectContext;
	NSNumber *sensorId;
	
	[LGUtils writeData:[NSData dataWithBytes:&dataToWrite length:sizeof(dataToWrite)]
		   charactUUID:@"SENSOR_TEMP_WINDOW_CHARACTERISTIC_UUID"
		   serviceUUID:@"SENSOR_SERVICE_UUID"
			peripheral:peripheral completion:^(NSError *error) {
				NSLog(@"Error : %@", error);
				[LGUtils readDataFromCharactUUID:@"SENSOR_TEMP_DATA_CHARACTERISTIC_UUID"
									 serviceUUID:@"SENSOR_SERVICE_UUID"
									  peripheral:peripheral
									  completion:^(NSData *data, NSError *error) {
										  for(NSUInteger i = 0; i < data.length; ++i) {
											  Byte byte = 0;
											  [data getBytes:&byte range:NSMakeRange(i, 1)];
											  [tempArrayBytes addObject:[NSString stringWithFormat:@"%hhu", byte]];
										  }
										  
										  [LGUtils writeData:[NSData dataWithBytes:&dataToWrite length:sizeof(dataToWrite)]
												 charactUUID:@"SENSOR_HUM_WINDOW_CHARACTERISTIC_UUID"
												 serviceUUID:@"SENSOR_SERVICE_UUID"
												  peripheral:peripheral completion:^(NSError *error) {
													  
													  [LGUtils readDataFromCharactUUID:@"SENSOR_HUM_DATA_CHARACTERISTIC_UUID"
																		   serviceUUID:@"SENSOR_SERVICE_UUID"
																			peripheral:peripheral
																			completion:^(NSData *data, NSError *error) {
																				for(NSUInteger i = 0; i < data.length; ++i) {
																					Byte byte = 0;
																					[data getBytes:&byte range:NSMakeRange(i, 1)];
																					[humArrayBytes addObject:[NSString stringWithFormat:@"%hhu", byte]];
																				}
																				//REDO
																				NSLog(@"Error : %@ -> Index : %ld", error, (long)indexDownload);
																				[self reWriteAndRead:peripheral];
																			}];
												  }];
									  }];
			}];
}


- (void)reWriteAndRead:(LGPeripheral *)peripheral {
	NSMutableArray *tempArrayFloat = [NSMutableArray array];
	NSMutableArray *tempArrayBytes = [NSMutableArray array];
	NSMutableArray *humArrayFloat = [NSMutableArray array];
	NSMutableArray *humArrayBytes = [NSMutableArray array];
	NSDate *maxDate;
	NSInteger indexDownload = 0;
	NSDate *nowDate;
	NSManagedObjectContext *managedObjectContext;
	NSNumber *sensorId;
	//TEMP
	[tempArrayFloat addObject:[NSNumber numberWithFloat:(float)([tempArrayBytes[3] integerValue] * 255 + [tempArrayBytes[2] integerValue])/10]];
	[tempArrayFloat addObject:[NSNumber numberWithFloat:(float)([tempArrayBytes[9] integerValue] * 255 + [tempArrayBytes[8] integerValue])/10]];
	[tempArrayFloat addObject:[NSNumber numberWithFloat:(float)([tempArrayBytes[15] integerValue] * 255 + [tempArrayBytes[14] integerValue])/10]];
	//HUM
	for (int i = 0; i < 12; i++) {
		[humArrayFloat addObject:[NSNumber numberWithFloat:(float)([humArrayBytes[i] integerValue])]];
	}
	
	NSTimeInterval distanceBetweenDates = [[NSDate date] timeIntervalSinceDate:maxDate];
	double secondsInAnHour = 3600;
	int maxIndex = distanceBetweenDates / secondsInAnHour;
	
	if (indexDownload > 100 || indexDownload > maxIndex+1) {
		
		for (int i=0; i<indexDownload; i++) {
			NSDate* localDate = [nowDate dateByAddingTimeInterval:-3600*i];
			if ([tempArrayFloat[i] floatValue] < 3264.0f &&  [humArrayFloat[i] floatValue] < 255.0f) {
				// ADD POINT
				// Create Entity
				NSEntityDescription *entityPoint = [NSEntityDescription entityForName:@"Point" inManagedObjectContext:managedObjectContext];
				
				// Initialize Record Temp
				NSManagedObject *recordPoint = [[NSManagedObject alloc] initWithEntity:entityPoint insertIntoManagedObjectContext:managedObjectContext];
				
				// Populate Record
				[recordPoint setValue:sensorId forKey:@"sensorId"];
				[recordPoint setValue:[NSDate date] forKey:@"createdAt"];
				[recordPoint setValue:localDate forKey:@"date"];
				[recordPoint setValue:tempArrayFloat[i] forKey:@"valueTemp"];
				[recordPoint setValue:humArrayFloat[i] forKey:@"valueHum"];
				
				//Save
				[managedObjectContext save:nil];
				NSLog(@"Save new point for date : %@", localDate);
				
			}
		}
		
		
	}
	else {
		//CONTINUE if not finished
		indexDownload = indexDownload + 1;
		[self writeAndRead:(int16_t)indexDownload peripheral:peripheral];
	}
	
}

@end
