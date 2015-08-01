//
//  OptionsTableViewController.m
//  wishbox
//
//  Copyright (c) 2015 Dmitry Mirkitanov. All rights reserved.
//

#import "OptionsTableViewController.h"
#import "SubscribeViewController.h"
#import "AppDelegate.h"
#import "DataProvider.h"
#import "Wishlist.h"

#import <Instabug/Instabug.h>

@interface OptionsTableViewController () <UITextFieldDelegate, SubscribeViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UITableViewCell *accountInfoCell;

@property (weak, nonatomic) IBOutlet UIImageView *accountTypeImageView;
@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet UISwitch *sharingEnabledSwitch;
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;

@property (nonatomic, strong) NSString *savedName;
@property (nonatomic, strong) NSString *savedEmail;

@end

@implementation OptionsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
 
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    
    [[NSNotificationCenter defaultCenter] addObserverForName:kDataProviderNotificationUserUpdated object:nil queue:nil usingBlock:^(NSNotification *note) {
        [self updateTableView];
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    [self updateTableView];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [[Analytics sharedInstance] trackScreen:@"Options"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)updateTableView {
    self.nameTextField.text = [DataProvider sharedInstance].currentUser.name;
    NSString *accountType = [DataProvider sharedInstance].currentUser.accountType;
    if ([accountType isEqualToString:@"fb"]) {
        self.accountTypeImageView.image = [UIImage imageNamed:@"options_facebook"];
    } else if ([accountType isEqualToString:@"tw"]) {
        self.accountTypeImageView.image = [UIImage imageNamed:@"options_twitter"];
    } else {
        self.accountTypeImageView.image = nil;
    }
    
    self.sharingEnabledSwitch.on = [[DataProvider sharedInstance].userWishlist.enabled boolValue];
    
    NSDate *subscriptionExpiresAt = [DataProvider sharedInstance].currentUser.subscriptionExpiresAt;
    if (!subscriptionExpiresAt) {
        self.subscriptionInfoCell.textLabel.text = NSLocalizedString(@"Subscription is not active", nil);
        self.subscriptionInfoCell.textLabel.textColor = [UIColor grayColor];
        self.subscribeForNotificationsCell.textLabel.font = [UIFont fontWithName:@"OpenSans-Semibold" size:16];
    } else {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
        [dateFormatter setTimeStyle:NSDateFormatterNoStyle];

        self.subscriptionInfoCell.textLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Subscription valid until %@", nil), [dateFormatter stringFromDate:subscriptionExpiresAt]];
        self.subscriptionInfoCell.textLabel.textColor = [UIColor blackColor];
        self.subscribeForNotificationsCell.textLabel.font = [UIFont fontWithName:@"OpenSans" size:16];
    }

    self.emailTextField.text = [DataProvider sharedInstance].currentUser.email;

    __block NSString *countryName = nil;
    [[AppDelegate instance].countries enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSDictionary *item = obj;
        if ([[item[@"cid"] uppercaseString] isEqualToString:[[DataProvider sharedInstance].currentUser.appStoreCountry uppercaseString]]) {
            countryName = item[@"cname"];
            *stop = YES;
        }
    }];

    self.appStoreCountryCell.detailTextLabel.text = countryName;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (cell == self.logoutCell) {
        //[self dismissViewControllerAnimated:YES completion:^{
            [[AppDelegate instance] logout];
            [[AppDelegate instance].mainViewController switchToLoginControllerAnimated:YES];
        //}];
    } else if (cell == self.subscribeForNotificationsCell) {
        NSDate *subscriptionExpiresAt = [DataProvider sharedInstance].currentUser.subscriptionExpiresAt;
        if (!subscriptionExpiresAt) {
            [self performSegueWithIdentifier:@"showSubscribeViewController" sender:self];
        } else {
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
            [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
            
            NSString *message = [NSString stringWithFormat:NSLocalizedString(@"Your subscription is valid until %@, would you like to extend it?", nil), [dateFormatter stringFromDate:subscriptionExpiresAt]];
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Subscription", nil) message:message preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                [alert dismissViewControllerAnimated:YES completion:nil];
            }]];
            [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Extend", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                [self performSegueWithIdentifier:@"showSubscribeViewController" sender:self];
            }]];
            [self presentViewController:alert animated:YES completion:nil];
        }
    } else if (cell == self.inviteFriendsCell) {
        NSMutableArray *sharingItems = [NSMutableArray new];
        [sharingItems addObject:NSLocalizedString(@"Wishbox — Know when an app you want goes on sale!", nil)];
        [sharingItems addObject:[NSURL URLWithString:@"http://getwishbox.net"]];
        
        UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:sharingItems applicationActivities:nil];
        activityController.popoverPresentationController.sourceView = cell;
        activityController.popoverPresentationController.sourceRect = cell.bounds;
        [self presentViewController:activityController animated:YES completion:nil];
    } else if (cell == self.sendFeedbackCell) {
        [Instabug invokeFeedbackSender];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showSubscribeViewController"]) {
        SubscribeViewController *viewController = segue.destinationViewController;
        viewController.delegate = self;
    }
}

- (IBAction)done:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    if (textField == self.nameTextField) {
        self.savedName = textField.text;
    } else if (textField == self.emailTextField) {
        self.savedEmail = textField.text;
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if (textField == self.nameTextField) {
        if (isEmpty(textField.text)) {
            textField.text = self.savedName;
        }
        
        if (![textField.text isEqualToString:[DataProvider sharedInstance].currentUser.name]) {
            NSString *prevName = [DataProvider sharedInstance].currentUser.name;
            [DataProvider sharedInstance].currentUser.name = textField.text;
            [[DataProvider sharedInstance] saveUserToServerWithSuccess:nil failure:^(NSError *error) {
                [DataProvider sharedInstance].currentUser.name = prevName;
                [self updateTableView];

                UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", nil) message:NSLocalizedString(@"An error occurred while updating a name. Please try again.", nil) preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {}];
                [alert addAction:defaultAction];
                [self presentViewController:alert animated:YES completion:nil];
            }];
        }
        
        self.savedName = nil;
    } else if (textField == self.emailTextField) {
        NSString *updatedEmail = textField.text;
        if (isEmpty(updatedEmail)) {
            // TODO: ask user to confirm
        }
        
        if (![updatedEmail isEqualToString:[DataProvider sharedInstance].currentUser.email]) {
            NSString *prevEmail = [DataProvider sharedInstance].currentUser.email;
            [DataProvider sharedInstance].currentUser.email = updatedEmail;
            [[DataProvider sharedInstance] saveUserToServerWithSuccess:^{
                if (!isEmpty(updatedEmail)) {
                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Success", nil) message:NSLocalizedString(@"Your email address has been changed.\nPlease note that you need to verify it - we've sent an email with a confirmation link to the specified address.", nil) preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {}];
                    [alert addAction:defaultAction];
                    [self presentViewController:alert animated:YES completion:nil];
                }
            } failure:^(NSError *error) {
                [DataProvider sharedInstance].currentUser.email = prevEmail;
                [self updateTableView];
                
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", nil) message:NSLocalizedString(@"An error occurred while updating an email, check it and try again.", nil) preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {}];
                [alert addAction:defaultAction];
                [self presentViewController:alert animated:YES completion:nil];
            }];
        }
        
        self.savedEmail = nil;
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (IBAction)enableWishlistValueChanged:(id)sender {
    BOOL updatedState = self.sharingEnabledSwitch.on;

    void (^updateBlock)() = ^{
        [DataProvider sharedInstance].userWishlist.enabled = @(updatedState);
        [[DataProvider sharedInstance] saveUserWishlistToServerWithSuccess:nil failure:^(NSError *error) {
            [DataProvider sharedInstance].userWishlist.enabled = @(!updatedState);
            self.sharingEnabledSwitch.on = !updatedState;
            
            NSString *message = [NSString stringWithFormat:NSLocalizedString(@"An error occurred while %@ wishlist sharing. Please try again.", nil), (updatedState ? NSLocalizedString(@"enabling", nil) : NSLocalizedString(@"disabling", nil))];
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", nil) message:message preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {}];
            [alert addAction:defaultAction];
            [self presentViewController:alert animated:YES completion:nil];
        }];
    };
    
    if (updatedState == NO) {
        NSString *message = NSLocalizedString(@"If you disable wishlist sharing, your wishlist will be hidden from users who have already viewed it, and existing shared links will stop working. Are you sure you want to disable it?", nil);
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Disable wishlist sharing", nil) message:message preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            self.sharingEnabledSwitch.on = YES;
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Disable", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            updateBlock();
        }]];
        [self presentViewController:alert animated:YES completion:nil];
    } else {
        updateBlock();
    }
}

- (IBAction)unwindToOptionsTableViewController:(UIStoryboardSegue *)unwindSegue {
}

#pragma mark - SubscribeViewControllerDelegate

- (void)subscribeViewControllerDidSubscribe:(SubscribeViewController *)viewController {
    [[AppDelegate instance] setShouldRegisterPushNotifications];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Success" message:@"Thank you! Your subscription purchase was successful." preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [[AppDelegate instance] registerForPushNotifications];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
