//
//  AppTableViewController.h
//  wishbox
//
//  Copyright (c) 2015 Dmitry Mirkitanov. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Wishlist;
@class App;

@interface AppTableViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong, readonly) UIRefreshControl *refreshControl;

@property (nonatomic, strong, readonly) UITableViewController *tableViewController;
@property (nonatomic, weak, readonly) UITableView *tableView;

@property (nonatomic, strong, readonly) NSMutableDictionary *sections;
@property (nonatomic, strong, readonly) NSMutableDictionary *sectionToAppPriceTypeMap;

- (void)updateFromWishlist:(Wishlist *)wishlist;
- (void)updateFromWishlist:(Wishlist *)wishlist reloadData:(BOOL)reloadData;
- (App *)appForIndexPath:(NSIndexPath *)indexPath;

@property (nonatomic) BOOL pinToLayoutGuide;


@end
