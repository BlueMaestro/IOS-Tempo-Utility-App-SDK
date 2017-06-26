//
//  TDUARTDownloader.h
//  TempoDisc
//
//  Created by Nikola Misic on 10/5/16.
//  Copyright © 2016 BlueMaestro. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TempoDiscDevice+CoreDataProperties.h"

typedef void(^DataDownloadCompletion)(BOOL);

typedef void(^DataProgressUpdate)(float progress);

@interface TDUARTDownloader : NSObject

+ (TDUARTDownloader*)shared;

- (void)downloadDataForDevice:(TempoDiscDevice*)device withUpdate:(DataProgressUpdate)update withCompletion:(DataDownloadCompletion)completion;

- (void)downloadDataForDevice:(TempoDiscDevice*)device withCompletion:(DataDownloadCompletion)completion;

- (void)setNewTimeStamp: (NSInteger)sendRecordsNeeded;

- (void)notifyUpdateForProgress:(float)progress;
@end
