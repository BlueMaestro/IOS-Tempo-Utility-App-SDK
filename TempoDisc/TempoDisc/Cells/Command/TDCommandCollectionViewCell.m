//
//  TDCommandCollectionViewCell.m
//  Tempo Utility
//
//  Created by Nikola Misic on 1/18/17.
//  Copyright © 2017 BlueMaestro. All rights reserved.
//

#import "TDCommandCollectionViewCell.h"

@implementation TDCommandCollectionViewCell

- (void)awakeFromNib {
	[super awakeFromNib];
	_labelCommandName.layer.cornerRadius = 8;
	_labelCommandName.layer.borderColor = [UIColor commandBorder].CGColor;
	_labelCommandName.layer.borderWidth = 1.0;
    _labelCommandName.layer.backgroundColor = [UIColor commandBorder].CGColor;
}

@end
