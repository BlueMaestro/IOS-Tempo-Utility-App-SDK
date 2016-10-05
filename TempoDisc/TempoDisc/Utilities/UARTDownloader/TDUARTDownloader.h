//
//  TDUARTDownloader.h
//  TempoDisc
//
//  Created by Nikola Misic on 10/5/16.
//  Copyright © 2016 BlueMaestro. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TempoDiscDevice+CoreDataProperties.h"

typedef void(^DataDownloadCompletion)(void);

@interface TDUARTDownloader : NSObject

+ (TDUARTDownloader*)shared;

- (void)downloadDataForDevice:(TempoDiscDevice*)device withCompletion:(DataDownloadCompletion)completion;

@end
