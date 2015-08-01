//
//  FriendAppsViewController.m
//  wishbox
//
//  Copyright (c) 2015 Dmitry Mirkitanov. All rights reserved.
//

#import "FriendAppsViewController.h"
#import "DataProvider.h"
#import "Wishlist.h"
#import "App.h"

@interface FriendAppsViewController ()

@property (weak, nonatomic) IBOutlet UIBarButtonItem *likeBarButtonItem;
@property (nonatomic) BOOL visible;

@end

@implementation FriendAppsViewController

- (void)viewDidLoad {
    self.pinToLayoutGuide = YES;
    
    [super viewDidLoad];
    
    self.tableView.estimatedRowHeight = 77.0;
    self.tableView.rowHeight = UITableViewAutomaticDimension;

    [[NSNotificationCenter defaultCenter] addObserverForName:kDataProviderNotificationFollowedWishlistsUpdated object:nil queue:nil usingBlock:^(NSNotification *note) {
        Wishlist *wishlist = [DataProvider sharedInstance].followedWishlists[self.urlKey];
        if (wishlist) {
            [self updateFromWishlist:wishlist];
        }
    }];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    Wishlist *wishlist = [DataProvider sharedInstance].followedWishlists[self.urlKey];
    if (!wishlist) {        // no such wishlist, try to load
        self.title = nil;
        self.likeBarButtonItem.image = nil;
        self.likeBarButtonItem.enabled = NO;

        [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeClear];
        [[DataProvider sharedInstance] loadFollowedWishlist:self.urlKey success:^(Wishlist *wishlist) {
            [SVProgressHUD dismiss];
            
            [self updateFromWishlist:wishlist];
        } failure:^(NSError *error) {
            [SVProgressHUD dismiss];
        }];
    } else {
        [self updateFromWishlist:wishlist];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [[Analytics sharedInstance] trackScreen:@"Friend Apps"];
    self.visible = YES;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    self.visible = NO;
}


- (void)updateFromWishlist:(Wishlist *)wishlist {
    self.title = wishlist.name;
    self.likeBarButtonItem.enabled = YES;
    self.likeBarButtonItem.image = [UIImage imageNamed:([wishlist.liked boolValue] ? @"navbar_icon_star_full" : @"navbar_icon_star_empty")];
    
    [super updateFromWishlist:wishlist];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    alert.popoverPresentationController.sourceView = [self.tableView cellForRowAtIndexPath:indexPath];
    alert.popoverPresentationController.sourceRect = [self.tableView cellForRowAtIndexPath:indexPath].bounds;
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Install", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        App *app = [self appForIndexPath:indexPath];
        NSString *urlString = [NSString stringWithFormat:@"itms-apps://itunes.apple.com/app/id%@", app.appStoreId];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Add to my wishlist", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {

        
        [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeClear];

        App *app = [self appForIndexPath:indexPath];
        [[DataProvider sharedInstance] addApp:app success:^{
            [SVProgressHUD showSuccessWithStatus:nil];
        } failure:^(NSError *error) {
            [SVProgressHUD dismiss];

            UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", nil)
                                                                           message:NSLocalizedString(@"An error occurred while adding the app to your wishlist. Please try again.", nil)
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                                  handler:^(UIAlertAction * action) {}];
            [alert addAction:defaultAction];
            [self presentViewController:alert animated:YES completion:nil];
        }];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (IBAction)refresh:(id)sender {
    [[DataProvider sharedInstance] loadFollowedWishlist:self.urlKey success:^(Wishlist *wishlist) {
        [self updateFromWishlist:wishlist];
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

- (IBAction)like:(id)sender {
    Wishlist *wishlist = [DataProvider sharedInstance].followedWishlists[self.urlKey];
    if (!wishlist)
        return;
    
    NSString *blockUrlKey = self.urlKey;
    BOOL requestedLikeState = ![wishlist.liked boolValue];
    
    [SVProgressHUD showImage:[UIImage imageNamed:(requestedLikeState ? @"hud_star_full" : @"hud_star_empty")]
                      status:(requestedLikeState ? @"Starred" : @"Unstarred")];
    
    [[DataProvider sharedInstance] updateLikeState:requestedLikeState forFollowedWishlist:self.urlKey success:nil failure:^(NSError *error) {
        if (!self.visible || ![self.urlKey isEqualToString:blockUrlKey])
            return;

        NSString *message = [NSString stringWithFormat:NSLocalizedString(@"An error occurred while %@ your friend's wishlist. Please try again.", nil), (requestedLikeState ? @"starring" : @"unstarring")];
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", nil)
                                                                       message:message
                                                                preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {}];
        [alert addAction:defaultAction];
        [self presentViewController:alert animated:YES completion:nil];

    }];
}

@end
