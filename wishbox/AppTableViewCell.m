//
//  AppTableViewCell.m
//  wishbox
//
//  Copyright (c) 2015 Dmitry Mirkitanov. All rights reserved.
//

#import "AppTableViewCell.h"

@implementation AppTableViewCell

- (void)awakeFromNib {
    self.iconImageView.layer.cornerRadius = 13;
    self.iconImageView.layer.masksToBounds = YES;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
