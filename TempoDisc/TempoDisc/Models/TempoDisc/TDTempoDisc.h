//
//  TDTempoDisc.h
//  Tempo Utility
//
//  Created by Nikola Misic on 2/22/17.
//  Copyright © 2017 BlueMaestro. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <LGBluetooth/LGPeripheral.h>

@interface TDTempoDisc : NSObject

@property (nullable ,nonatomic, strong) LGPeripheral *peripheral;

@property (nullable, nonatomic, strong) NSString *uuid;
@property (nullable, nonatomic, strong) NSString *name;
@property (nullable, nonatomic, strong) NSNumber *battery;
@property (nullable, nonatomic, strong) NSString *modelType;
@property (nullable, nonatomic, strong) NSNumber *version;
@property (nullable, nonatomic, strong) NSNumber *currentTemperature;
@property (nullable, nonatomic, strong) NSNumber *currentMinTemperature;
@property (nullable, nonatomic, strong) NSNumber *currentMaxTemperature;
@property (nullable, nonatomic, strong) NSNumber *currentHumidity;
@property (nullable, nonatomic, strong) NSNumber *currentPressure;
@property (nullable, nonatomic, strong) NSNumber *currentPressureData;
@property (nullable, nonatomic, strong) NSDate *lastDownload;
@property (nullable, nonatomic, strong) NSNumber *isBlueMaestroDevice;
@property (nullable, nonatomic, strong) NSNumber *isFahrenheit;//BOOL
@property (nullable, nonatomic, strong) NSNumber *inRange;//BOOL, transient
@property (nullable, nonatomic, strong) NSDate *startTimestamp;
@property (nullable, nonatomic, strong) NSDate *lastDetected;//transient
@property (nullable, nonatomic, strong) NSNumber *timerInterval;
@property (nullable, nonatomic, strong) NSNumber *intervalCounter;
@property (nullable, nonatomic, strong) NSNumber *dewPoint;
@property (nullable, nonatomic, strong) NSNumber *mode;
@property (nullable, nonatomic, strong) NSNumber *numBreach;
@property (nullable, nonatomic, strong) NSNumber *highestTemperature;
@property (nullable, nonatomic, strong) NSNumber *highestHumidity;
@property (nullable, nonatomic, strong) NSNumber *highestDew;
@property (nullable, nonatomic, strong) NSNumber *lowestTemperature;
@property (nullable, nonatomic, strong) NSNumber *lowestHumidity;
@property (nullable, nonatomic, strong) NSNumber *lowestDew;
@property (nullable, nonatomic, strong) NSNumber *highestDayTemperature;
@property (nullable, nonatomic, strong) NSNumber *highestDayHumidity;
@property (nullable, nonatomic, strong) NSNumber *highestDayDew;
@property (nullable, nonatomic, strong) NSNumber *lowestDayTemperature;
@property (nullable, nonatomic, strong) NSNumber *lowestDayHumidity;
@property (nullable, nonatomic, strong) NSNumber *lowestDayDew;
@property (nullable, nonatomic, strong) NSNumber *averageDayTemperature;
@property (nullable, nonatomic, strong) NSNumber *averageDayHumidity;
@property (nullable, nonatomic, strong) NSNumber *averageDayDew;
@property (nullable, nonatomic, strong) NSNumber *logCount;
@property (nullable, nonatomic, strong) NSNumber *referenceDateRawNumber;
@property (nullable, nonatomic, strong) NSNumber *globalIdentifier;
@property (nullable, nonatomic, strong) NSNumber *averageDayPressure;
@property (nullable, nonatomic, strong) NSNumber *pressure;
@property (nullable, nonatomic, strong) NSNumber *highestDayPressure;
@property (nullable, nonatomic, strong) NSNumber *highestPressure;
@property (nullable, nonatomic, strong) NSNumber *lowestDayPressure;
@property (nullable, nonatomic, strong) NSNumber *lowestPressure;
@property (nullable, nonatomic, strong) NSNumber *altitude;

//device 32
@property (nullable, nonatomic, strong) NSNumber *humSensitivityLevel;
@property (nullable, nonatomic, strong) NSNumber *pestSensitivityLevel;
@property (nullable, nonatomic, strong) NSNumber *force;
@property (nullable, nonatomic, strong) NSNumber *movementMeasurePeriod;
@property (nullable, nonatomic, strong) NSNumber *dateNumber;
@property (nullable, nonatomic, strong) NSNumber *buttonPressControl;//also for version 42
@property (nullable, nonatomic, strong) NSNumber *lastPestDetectRate;
@property (nullable, nonatomic, strong) NSNumber *lastHumDetectRate;
@property (nullable, nonatomic, strong) NSNumber *totalPestEventsDetects;
@property (nullable, nonatomic, strong) NSNumber *totalHumEventsDetects;
@property (nullable, nonatomic, strong) NSNumber *lastButtonDetected;

//version 42
@property (nullable, nonatomic, strong) NSNumber *totalButtonEvents;

- (void)fillWithData:(NSDictionary *)advertisedData name:(NSString *)name uuid:(NSString *)uuid;

- (TempoDeviceType)deviceType;

@end
