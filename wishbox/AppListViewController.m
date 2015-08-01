//
//  AppListViewController.m
//  wishbox
//
//  Copyright (c) 2015 Dmitry Mirkitanov. All rights reserved.
//

#import "AppListViewController.h"
#import "DataProvider.h"
#import "SocialViewController.h"
#import "App.h"
#import "Wishlist.h"
#import "User.h"

@interface AppListViewController ()

@property (nonatomic, strong) NSString *urlKeyForManualSegue;
@property (nonatomic) BOOL visible;
@property (weak, nonatomic) IBOutlet UIButton *learnHowToAddButton;

@end

@implementation AppListViewController

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (void)viewDidLoad {
    self.pinToLayoutGuide = YES;
    
    [super viewDidLoad];
    
    self.learnHowToAddButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    
    self.tableView.estimatedRowHeight = 77.0;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    [self setNeedsStatusBarAppearanceUpdate];

    [self updateFromWishlist:[DataProvider sharedInstance].userWishlist];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:kDataProviderNotificationUserWishlistUpdated object:nil queue:nil usingBlock:^(NSNotification *note) {
        [self updateFromWishlist:[DataProvider sharedInstance].userWishlist];
    }];
}

- (void)updateFromWishlist:(Wishlist *)wishlist {
    [super updateFromWishlist:wishlist];

    self.tableViewController.view.hidden = ([self.tableView numberOfSections] == 0);

    [self checkAndShowSubscribeAlertIfNeeded];
}

- (void)checkAndShowSubscribeAlertIfNeeded {
    if (!self.visible || [self.sections count] == 0)
        return;
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"onboardingSubscribeReminderWasShown"])
        return;
    
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"onboardingSubscribeReminderWasShown"];
    [[NSUserDefaults standardUserDefaults] synchronize];

#ifdef ENABLE_SUBSCRIPTION
    NSString *message = NSLocalizedString(@"Congratulations! You've added the first app to your wishlist.\n\nDo you want to receive notifications about price changes for the apps in your wishlist?", nil);
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Notifications", nil) message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Maybe Later", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [alert dismissViewControllerAnimated:YES completion:nil];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Yes!", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self performSegueWithIdentifier:@"showSubscribeFromAppList" sender:self];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
#else
    if (isEmpty([DataProvider sharedInstance].currentUser.email)) {
        NSString *message = NSLocalizedString(@"Congratulations! You've added the first app to your wishlist.\n\nTo receive notifications about price changes for the apps in your wishlist you need to provide your email address. Do you want to set it now?", nil);
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Notifications", nil) message:message preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Maybe Later", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [alert dismissViewControllerAnimated:YES completion:nil];
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Yes", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self performSegueWithIdentifier:@"showOptionsSegue" sender:self];
        }]];
        [self presentViewController:alert animated:YES completion:nil];
    }
#endif
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [[Analytics sharedInstance] trackScreen:@"App List"];

    self.visible = YES;

    if (self.urlKeyTrigger) {
        [self performSegueWithIdentifier:@"showSocialWithoutAnimation" sender:self];
    } else if (![[NSUserDefaults standardUserDefaults] boolForKey:@"onboardingTutorialWasShown"]) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"onboardingTutorialWasShown"];
        [[NSUserDefaults standardUserDefaults] synchronize];

        [self performSegueWithIdentifier:@"showTutorial" sender:self];
    } else {
        [self checkAndShowSubscribeAlertIfNeeded];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    self.visible = NO;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showSocialWithoutAnimation"]) {
        if (self.urlKeyTrigger) {
            UINavigationController *navigationController = segue.destinationViewController;
            SocialViewController *socialViewController = navigationController.viewControllers[0];
            socialViewController.urlKeyTrigger = self.urlKeyTrigger;
            
            self.urlKeyTrigger = nil;
        }
        
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        App *app = [self appForIndexPath:indexPath];

        NSMutableArray *apps = [NSMutableArray arrayWithArray:[DataProvider sharedInstance].userWishlist.apps];
        NSUInteger idx = [apps indexOfObject:app];
        
        // actually delete it
        [[DataProvider sharedInstance] deleteWishlistApp:app success:nil failure:^(NSError *error) {
            if (!self.visible)
                return;
            
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", nil) message:NSLocalizedString(@"An error occurred while removing the app. Please try again.", nil) preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {}];
            [alert addAction:defaultAction];
            [self presentViewController:alert animated:YES completion:nil];
        }];

        if (idx != NSNotFound) {
            NSNumber *appPriceType = self.sectionToAppPriceTypeMap[@(indexPath.section)];
            NSDictionary *section = self.sections[appPriceType];
            BOOL shouldRemoveSection = ([section count] == 1);
            
            [self updateFromWishlist:[DataProvider sharedInstance].userWishlist reloadData:NO];
            
            if (shouldRemoveSection)
                [tableView deleteSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationLeft];
            else
                [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationLeft];

            self.tableViewController.view.hidden = ([self.tableView numberOfSections] == 0);
        }
    }
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
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)refresh:(id)sender {
    [[DataProvider sharedInstance] updateUserWishlistWithSuccess:^{
        [self updateFromWishlist:[DataProvider sharedInstance].userWishlist];
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

- (IBAction)onLearnHowToAddButtonClick:(id)sender {
    [self performSegueWithIdentifier:@"showTutorial" sender:self];
}

@end
