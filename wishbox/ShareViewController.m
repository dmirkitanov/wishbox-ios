//
//  ShareViewController.m
//  wishbox
//
//  Copyright (c) 2015 Dmitry Mirkitanov. All rights reserved.
//

#import "ShareViewController.h"
#import <MessageUI/MessageUI.h>
#import <FacebookSDK/FacebookSDK.h>
#import <TwitterKit/TwitterKit.h>
#import "DataProvider.h"
#import "Wishlist.h"

@interface ShareViewController () <MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UIButton *shareWithTextButton;
@property (weak, nonatomic) IBOutlet UIButton *shareWithEmailButton;
@property (weak, nonatomic) IBOutlet UIButton *shareWithOtherButton;

@property (weak, nonatomic) IBOutlet UILabel *shareWithEmailLabel;
@property (weak, nonatomic) IBOutlet UILabel *shareWithTextLabel;

@property (weak, nonatomic) IBOutlet UILabel *starsCountLabel;

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIView *hline1;
@property (weak, nonatomic) IBOutlet UIView *hline2;

@property (nonatomic, strong) NSString *shareMessage;

@end

@implementation ShareViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.shareMessage = NSLocalizedString(@"My iOS wishlist on Wishbox", nil);
    
    BOOL mailEnabled = [MFMailComposeViewController canSendMail];
    self.shareWithEmailButton.enabled = mailEnabled;
    self.shareWithEmailLabel.enabled = mailEnabled;
    
    BOOL textEnabled = [MFMessageComposeViewController canSendText];
    self.shareWithTextButton.enabled = textEnabled;
    self.shareWithTextLabel.enabled = textEnabled;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
#ifdef APPSTORE_SCREENSHOTS
    self.starsCountLabel.text = @"42";
#else
    self.starsCountLabel.text = [[DataProvider sharedInstance].userWishlist.likesCount stringValue];
#endif
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [[Analytics sharedInstance] trackScreen:@"Share"];
}

- (void)updateViewConstraints {
    [super updateViewConstraints];
    
    CGFloat scale = [[UIScreen mainScreen] scale];
    CGFloat borderWidth = scale > 0.0 ? 1.0 / scale : 1.0;

    [self.hline1 mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@(borderWidth));
    }];

    [self.hline2 mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@(borderWidth));
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)checkWishlistStateWithSuccess:(void (^)())successBlock {
    if ([[DataProvider sharedInstance].userWishlist.enabled boolValue]) {
        if (successBlock)
            successBlock();
        return;
    }
    
    NSString *message = NSLocalizedString(@"Wishlist sharing is currently disabled. Do you want to enable it?\nYou can always disable it from the options menu.", nil);
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Enable wishlist sharing", nil) message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [alert dismissViewControllerAnimated:YES completion:nil];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Enable", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeClear];

        [DataProvider sharedInstance].userWishlist.enabled = @(YES);
        [[DataProvider sharedInstance] saveUserWishlistToServerWithSuccess:^{
            [SVProgressHUD dismiss];
            
            if (successBlock)
                successBlock();
        } failure:^(NSError *error) {
            [SVProgressHUD dismiss];

            [DataProvider sharedInstance].userWishlist.enabled = @(NO);

            NSString *message = NSLocalizedString(@"An error occurred while enabling wishlist sharing. Please try again.", nil);
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", nil) message:message preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {}];
            [alert addAction:defaultAction];
            [self presentViewController:alert animated:YES completion:nil];
        }];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (NSDictionary*)facebookFeedDialogParseURLParams:(NSString *)query {
    NSArray *pairs = [query componentsSeparatedByString:@"&"];
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    for (NSString *pair in pairs) {
        NSArray *kv = [pair componentsSeparatedByString:@"="];
        NSString *val =
        [kv[1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        params[kv[0]] = val;
    }
    return params;
}

- (IBAction)shareWithFacebook:(id)sender {
    [self checkWishlistStateWithSuccess:^{
        
        NSString *link = [DataProvider sharedInstance].userWishlist.shareUrl;
        
        FBLinkShareParams *params = [[FBLinkShareParams alloc] initWithLink:[NSURL URLWithString:link] name:self.shareMessage caption:nil description:nil picture:nil];
        if ([FBDialogs canPresentShareDialogWithParams:params]) {
            [FBDialogs presentShareDialogWithParams:params clientState:nil handler:^(FBAppCall *call, NSDictionary *results, NSError *error) {
                if (error) {
                    NSLog(@"Error publishing post: %@", error.description);
                    return;
                }
                
                NSLog(@"post publishing results: %@", results);
                
                BOOL didComplete = [results[@"didComplete"] boolValue];
                if (!didComplete) {
                    return;
                }
                
                NSString *completionGesture = results[@"completionGesture"];
                if (!isEmpty(completionGesture) && [completionGesture isEqual:@"cancel"]) {
                    return;
                }
            }];
        } else {
            NSMutableDictionary *params = [NSMutableDictionary dictionary];
            
            params[@"name"] = self.shareMessage;
            if (!isEmpty(link))
                params[@"link"] = link;
            
            // Show the feed dialog
            [FBWebDialogs presentFeedDialogModallyWithSession:nil parameters:params handler:^(FBWebDialogResult result, NSURL *resultURL, NSError *error) {
                if (error) {
                    // An error occurred, we need to handle the error
                    // See: https://developers.facebook.com/docs/ios/errors
                    NSLog(@"Error publishing story: %@", error.description);
                    return;
                }
                
                if (result == FBWebDialogResultDialogNotCompleted) {
                    NSLog(@"User cancelled.");
                    return;
                }
                
                // Handle the publish feed callback
                NSDictionary *urlParams = [self facebookFeedDialogParseURLParams:[resultURL query]];
                
                if (![urlParams valueForKey:@"post_id"]) {
                    NSLog(@"User cancelled.");
                    return;
                }
                
                // User clicked the Share button
                NSLog(@"Posted story, id: %@", [urlParams valueForKey:@"post_id"]);
            }];
        }
    }];
}

- (IBAction)shareWithTwitter:(id)sender {
    [self checkWishlistStateWithSuccess:^{
        TWTRComposer *composer = [[TWTRComposer alloc] init];
        
        [composer setText:[NSString stringWithFormat:@"%@ %@",self.shareMessage, [DataProvider sharedInstance].userWishlist.shareUrl]];
        
        [composer showWithCompletion:^(TWTRComposerResult result) {
            if (result == TWTRComposerResultCancelled) {
                NSLog(@"Tweet composition cancelled");
            }
            else {
                NSLog(@"Sending Tweet!");
            }
        }];
    }];
}

- (IBAction)shareWithEmail:(id)sender {
    [self checkWishlistStateWithSuccess:^{
        MFMailComposeViewController *controller = [[MFMailComposeViewController alloc] init];
        [controller setMessageBody:[NSString stringWithFormat:@"%@\n%@",self.shareMessage, [DataProvider sharedInstance].userWishlist.shareUrl] isHTML:NO];
        controller.mailComposeDelegate = self;
        [self presentViewController:controller animated:YES completion:nil];
    }];
}

- (IBAction)shareWithText:(id)sender {
    [self checkWishlistStateWithSuccess:^{
        MFMessageComposeViewController *controller = [[MFMessageComposeViewController alloc] init];
        controller.body = [NSString stringWithFormat:@"%@ %@",self.shareMessage, [DataProvider sharedInstance].userWishlist.shareUrl];
        controller.messageComposeDelegate = self;
        [self presentViewController:controller animated:YES completion:nil];
    }];
}

- (IBAction)shareWithCopyLink:(id)sender {
    [self checkWishlistStateWithSuccess:^{
        [[UIPasteboard generalPasteboard] setString:[DataProvider sharedInstance].userWishlist.shareUrl];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [SVProgressHUD showSuccessWithStatus:@"Copied!"];
        });
    }];
}

- (IBAction)shareWithOther:(id)sender {
    [self checkWishlistStateWithSuccess:^{
        NSMutableArray *sharingItems = [NSMutableArray new];
        [sharingItems addObject:self.shareMessage];
        [sharingItems addObject:[NSURL URLWithString:[DataProvider sharedInstance].userWishlist.shareUrl]];
        
        UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:sharingItems applicationActivities:nil];
        activityController.popoverPresentationController.sourceView = self.shareWithOtherButton;
        activityController.popoverPresentationController.sourceRect = self.shareWithOtherButton.bounds;
        [self presentViewController:activityController animated:YES completion:nil];
    }];
}


#pragma mark - MFMessageComposeViewControllerDelegate

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result {
    [controller dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    [controller dismissViewControllerAnimated:YES completion:nil];
}

@end
