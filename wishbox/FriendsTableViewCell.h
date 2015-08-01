//
//  FriendsTableViewCell.h
//  wishbox
//
//  Copyright (c) 2015 Dmitry Mirkitanov. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FriendsTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *listTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *appCountLabel;
@property (weak, nonatomic) IBOutlet UILabel *appLabel;
@property (weak, nonatomic) IBOutlet UIImageView *favoriteImageView;

@end
