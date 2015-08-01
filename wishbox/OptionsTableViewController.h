//
//  OptionsTableViewController.h
//  wishbox
//
//  Copyright (c) 2015 Dmitry Mirkitanov. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OptionsTableViewController : UITableViewController

@property (weak, nonatomic) IBOutlet UITableViewCell *logoutCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *subscribeForNotificationsCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *subscriptionInfoCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *inviteFriendsCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *sendFeedbackCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *appStoreCountryCell;

@end
