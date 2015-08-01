//
//  FriendsTableViewController.m
//  wishbox
//
//  Copyright (c) 2015 Dmitry Mirkitanov. All rights reserved.
//

#import "FriendsTableViewController.h"
#import "FriendsTableViewCell.h"
#import "UIViewController+Additions.h"
#import "FriendAppsViewController.h"
#import "DataProvider.h"
#import "Wishlist.h"
#import "App.h"

@interface FriendsTableViewController ()

@property (nonatomic, strong, readwrite) UIRefreshControl *refreshControl;
@property (nonatomic, strong, readwrite) UITableViewController *tableViewController;
@property (nonatomic, weak, readwrite) UITableView *tableView;

@property (nonatomic, strong) NSArray *followedWishlists;
@property (nonatomic) BOOL visible;

@property (weak, nonatomic) IBOutlet UIButton *askToShareButton;

@end

@implementation FriendsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableViewController = [[UITableViewController alloc] init];
    self.tableViewController.tableView.delegate = self;
    self.tableViewController.tableView.dataSource = self;
    [self addChildViewController:self.tableViewController];
    [self.view addSubview:self.tableViewController.view];
    
    [self.tableViewController.view mas_makeConstraints:^(MASConstraintMaker *make) {
//        if (self.pinToLayoutGuide) {
            UIView *topLayoutGuide = (id)self.topLayoutGuide;
            make.top.equalTo(topLayoutGuide.mas_bottom);
//        } else {
//            make.top.equalTo(self.view);
//        }
        make.left.equalTo(self.view);
        make.right.equalTo(self.view);
        make.bottom.equalTo(self.view);
    }];
    
    [self.tableViewController didMoveToParentViewController:self];
    
    self.tableView = self.tableViewController.tableView;
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
    self.tableViewController.refreshControl = self.refreshControl;
    
    [self.tableView registerNib:[UINib nibWithNibName:@"FriendsTableViewCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"FriendsTableViewCell"];

    
    [self updateTableData];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:kDataProviderNotificationFollowedWishlistsUpdated object:nil queue:nil usingBlock:^(NSNotification *note) {
        [self updateTableData];
    }];

}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [[Analytics sharedInstance] trackScreen:@"Friends"];
    self.visible = YES;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    self.visible = NO;
}

#pragma mark - Table view data source

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        Wishlist *wishlist = self.followedWishlists[indexPath.row];

        [[DataProvider sharedInstance] deleteFollowedWishlist:wishlist.urlKey success:nil failure:^(NSError *error) {
            if (!self.visible)
                return;
            
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", nil)
                                                                           message:NSLocalizedString(@"An error occurred while unfollowing your friend's wishlist. Please try again.", nil)
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                                  handler:^(UIAlertAction * action) {}];
            
            [alert addAction:defaultAction];
            [self presentViewController:alert animated:YES completion:nil];
        }];

        [self updateTableDataWithReload:NO];
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationLeft];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.followedWishlists count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    FriendsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"FriendsTableViewCell" forIndexPath:indexPath];
    
    Wishlist *wishlist = self.followedWishlists[indexPath.row];
    NSInteger appsCount = [wishlist.apps count];
    
    cell.listTitleLabel.text = wishlist.name;
    cell.appCountLabel.text = [@(appsCount) stringValue];
    cell.appLabel.text = (appsCount == 1 ? @"app" : @"apps");
    cell.favoriteImageView.hidden = ![wishlist.liked boolValue];
    
    return cell;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showFriendsApps"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
        Wishlist *wishlist = self.followedWishlists[indexPath.row];

        FriendAppsViewController *friendAppsViewController = segue.destinationViewController;
        friendAppsViewController.urlKey = wishlist.urlKey;
    }
}

- (void)updateTableData {
    [self updateTableDataWithReload:YES];
}

- (void)updateTableDataWithReload:(BOOL)reload {
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];

#ifdef APPSTORE_SCREENSHOTS
    NSArray *data = @[
                      @{@"name": @"Craig S.", @"apps": @32, @"liked": @(YES)},
                      @{@"name": @"Charles B.", @"apps": @5, @"liked": @(NO)},
                      @{@"name": @"Katherine L.", @"apps": @12, @"liked": @(NO)},
                      @{@"name": @"Matthew J.", @"apps": @15, @"liked": @(NO)},
                      @{@"name": @"Carlos R.", @"apps": @42, @"liked": @(YES)},
                      @{@"name": @"Kathleen P.", @"apps": @33, @"liked": @(YES)},
                      @{@"name": @"Dorothy D.", @"apps": @16, @"liked": @(NO)},
                      @{@"name": @"Mary C.", @"apps": @6, @"liked": @(NO)},
                      @{@"name": @"Maria L.", @"apps": @29, @"liked": @(YES)},
                      @{@"name": @"Evelyn L.", @"apps": @10, @"liked": @(NO)},
                      @{@"name": @"Thomas T.", @"apps": @19, @"liked": @(YES)},
                      @{@"name": @"Paula A.", @"apps": @31, @"liked": @(NO)},
                      @{@"name": @"Kelly G.", @"apps": @20, @"liked": @(NO)},
                      ];
    
    NSMutableArray *followedWishlistsUnsorted = [NSMutableArray array];
    [data enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        Wishlist *wishlist = [[Wishlist alloc] init];
        NSMutableArray *apps = [NSMutableArray array];
        for (int i=0; i<[obj[@"apps"] integerValue]; i++) {
            App *app = [[App alloc] init];
            [apps addObject:app];
        }
        wishlist.apps = apps;
        wishlist.name = obj[@"name"];
        wishlist.liked = obj[@"liked"];
        [followedWishlistsUnsorted addObject:wishlist];
    }];
    
#else
    NSArray *followedWishlistsUnsorted = [[DataProvider sharedInstance].followedWishlists allValues];
#endif
    
    self.followedWishlists = [followedWishlistsUnsorted sortedArrayUsingDescriptors:@[sortDescriptor]];
    if (reload) {
        [self.tableView reloadData];
    }
    
    self.tableView.hidden = ([self.tableView numberOfRowsInSection:0] == 0);
}

- (IBAction)refresh:(id)sender {
    [[DataProvider sharedInstance] updateFollowedWishlistsWithSuccess:^{
        [self updateTableData];
        [self.tableView layoutIfNeeded];
        if ([self.refreshControl isRefreshing]) {
            [self.refreshControl endRefreshing];
        }
    } failure:^(NSError *error) {
        if ([self.refreshControl isRefreshing]) {
            [self.refreshControl endRefreshing];
        }
    }];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 50;
}

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    tableView.hidden = ([tableView numberOfRowsInSection:0] == 0);
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    [self performSegueWithIdentifier:@"showFriendsApps" sender:[tableView cellForRowAtIndexPath:indexPath]];
}

- (IBAction)onAskToShareButtonClick:(id)sender {
    NSMutableArray *sharingItems = [NSMutableArray new];

    [sharingItems addObject:NSLocalizedString(@"Wishbox — Know when an app you want goes on sale!", nil)];
    [sharingItems addObject:[NSURL URLWithString:@"http://getwishbox.net"]];
    
    UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:sharingItems applicationActivities:nil];
    activityController.popoverPresentationController.sourceView = self.askToShareButton;
    activityController.popoverPresentationController.sourceRect = self.askToShareButton.bounds;
    [self presentViewController:activityController animated:YES completion:nil];
}

@end
