//
//  TDCommandViewController.h
//  Tempo Utility
//
//  Created by Nikola Misic on 1/18/17.
//  Copyright © 2017 BlueMaestro. All rights reserved.
//

#import "TDUARTViewController.h"

@interface TDCommandViewController : TDUARTViewController <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (strong, nonatomic) IBOutlet UILabel *labelDeviceUUID;
@property (strong, nonatomic) IBOutlet UILabel *labelBatteryValue;
@property (strong, nonatomic) IBOutlet UILabel *labelRSSIValue;

@property (strong, nonatomic) IBOutlet UICollectionView *collectionViewCommands;
@end
