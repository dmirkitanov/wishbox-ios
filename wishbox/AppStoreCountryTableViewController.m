//
//  AppStoreCountryTableViewController.m
//  wishbox
//
//  Created by dm on 22/07/15.
//  Copyright (c) 2015 dm. All rights reserved.
//

#import "AppStoreCountryTableViewController.h"
#import "AppDelegate.h"
#import "DataProvider.h"

@interface AppStoreCountryTableViewController ()

@end

@implementation AppStoreCountryTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[AppDelegate instance].countries count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"countryCell" forIndexPath:indexPath];
    
    cell.textLabel.text = [AppDelegate instance].countries[indexPath.row][@"cname"];
    if ([[[AppDelegate instance].countries[indexPath.row][@"cid"] uppercaseString] isEqualToString:[[DataProvider sharedInstance].currentUser.appStoreCountry uppercaseString]]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *updatedAppStoreCountry = [AppDelegate instance].countries[indexPath.row][@"cid"];
    
    if (![updatedAppStoreCountry isEqualToString:[DataProvider sharedInstance].currentUser.appStoreCountry]) {
        NSString *prevAppStoreCountry = [DataProvider sharedInstance].currentUser.appStoreCountry;
        [DataProvider sharedInstance].currentUser.appStoreCountry = updatedAppStoreCountry;
        [[AppDelegate instance] setAppStoreCountry:updatedAppStoreCountry];
        [self.tableView reloadData];

        [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeGradient];

        [[DataProvider sharedInstance] saveUserToServerWithSuccess:^{
            [SVProgressHUD dismiss];

            [[DataProvider sharedInstance] updateWishlists];
            [self performSegueWithIdentifier:@"unwindToOptionsSegue" sender:self];
        } failure:^(NSError *error) {
            [SVProgressHUD dismiss];

            [DataProvider sharedInstance].currentUser.appStoreCountry = prevAppStoreCountry;
            [[AppDelegate instance] setAppStoreCountry:prevAppStoreCountry];
            [self.tableView reloadData];
            
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", nil) message:NSLocalizedString(@"An error occurred while updating an appstore country, please try again.", nil) preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {}];
            [alert addAction:defaultAction];
            [self presentViewController:alert animated:YES completion:nil];
        }];
    } else {
        [self performSegueWithIdentifier:@"unwindToOptionsSegue" sender:self];
    }
}

@end
