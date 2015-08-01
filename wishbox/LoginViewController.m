//
//  LoginViewController.m
//  wishbox
//
//  Copyright (c) 2015 Dmitry Mirkitanov. All rights reserved.
//

#import "LoginViewController.h"
#import "AppDelegate.h"
#import <FacebookSDK/FacebookSDK.h>
#import <TwitterKit/TwitterKit.h>

#import "User.h"

@interface LoginViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *logoImageView;
@property (weak, nonatomic) IBOutlet UIButton *facebookLoginButton;
@property (weak, nonatomic) IBOutlet UIButton *twitterLoginButton;

@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIImageView *facebookLogoImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"fb_logo_white"]];
    [self.facebookLoginButton addSubview:facebookLogoImageView];
    
    [facebookLogoImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.facebookLoginButton);
        make.centerX.equalTo(self.facebookLoginButton.mas_left).offset(24);
    }];


    UIImageView *twitterLogoImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"tw_logo_white"]];
    [self.twitterLoginButton addSubview:twitterLogoImageView];
    
    [twitterLogoImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.twitterLoginButton);
        make.centerX.equalTo(self.twitterLoginButton.mas_left).offset(24);
    }];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [[Analytics sharedInstance] trackScreen:@"Login"];
    [SVProgressHUD dismiss];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];

    [SVProgressHUD dismiss];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    [SVProgressHUD dismiss];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)showAlertWithTitle:(NSString *)alertTitle text:(NSString *)alertText {
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:alertTitle
                                                                   message:alertText
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {}];
    
    [alert addAction:defaultAction];
    [self presentViewController:alert animated:YES completion:nil];
}

- (IBAction)onFacebookLoginClick:(id)sender {
    if (FBSession.activeSession.state == FBSessionStateOpen || FBSession.activeSession.state == FBSessionStateOpenTokenExtended) {
        [FBSession.activeSession closeAndClearTokenInformation];
    }
    
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeGradient];
    
    [FBSession openActiveSessionWithReadPermissions:@[@"public_profile"] allowLoginUI:YES completionHandler:^(FBSession *session, FBSessionState state, NSError *error) {
        [[AppDelegate instance] facebookSessionStateChanged:session state:state error:error];
    }];
}

- (void)facebookSessionStateChanged:(FBSession *)session state:(FBSessionState)state error:(NSError *)error {
    [SVProgressHUD dismiss];
    
    if (!error && state == FBSessionStateOpen) {
        NSDictionary *authData = @{@"facebook": @{@"accessToken": session.accessTokenData.accessToken}};
        [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeGradient];
        [[AppDelegate instance] loginWithAuthData:authData success:^{
            [SVProgressHUD dismiss];
            [[AppDelegate instance].mainViewController switchToRootNavigationControllerAnimated:YES];
        } failure:^(NSError *error) {
            [SVProgressHUD dismiss];
            [self showAlertWithTitle:@"Error" text:@"Error while siging in, please try again"];
        }];
    } else {
        if (error) {
            NSString *alertText;
            NSString *alertTitle;
            
            if ([FBErrorUtility shouldNotifyUserForError:error]) {
                alertTitle = @"Error";
                alertText = [FBErrorUtility userMessageForError:error];
            } else {
                if ([FBErrorUtility errorCategoryForError:error] == FBErrorCategoryUserCancelled) {
                } else if ([FBErrorUtility errorCategoryForError:error] == FBErrorCategoryAuthenticationReopenSession) {
                    alertTitle = @"Session Error";
                    alertText = @"Your current facebook session is no longer valid. Please log in again.";
                } else {
                    alertTitle = @"Error";
                    alertText = @"Something went wrong, please retry";
                }
            }
            
            if (alertText) {
                [self showAlertWithTitle:alertTitle text:alertText];
            }
        }
    }
}

- (IBAction)onTwitterLoginClick:(id)sender {
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeGradient];
    
    [[Twitter sharedInstance] logOut];
    [[Twitter sharedInstance] logInWithCompletion:^(TWTRSession *session, NSError *error) {
        [SVProgressHUD dismiss];
        if (error) {
            DLog(@"User NOT logged in with Twitter! (%@)", error.description);
            return;
        }
        
        DLog(@"User logged in with Twitter!");
        
        TWTROAuthSigning *oauthSigning = [[TWTROAuthSigning alloc] initWithAuthConfig:[Twitter sharedInstance].authConfig authSession:[Twitter sharedInstance].session];
        if (!oauthSigning) {
            [SVProgressHUD dismiss];
            DLog(@"error getting oauthSigning (TWTROAuthSigning)!");
            [self showAlertWithTitle:@"Error" text:@"Error while siging in, please try again"];
            return;
        }
        
        NSDictionary *authData = @{@"twitter": [oauthSigning OAuthEchoHeadersToVerifyCredentials]};
        
        [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeGradient];
        [[AppDelegate instance] loginWithAuthData:authData success:^{
            [SVProgressHUD dismiss];
            [[AppDelegate instance].mainViewController switchToRootNavigationControllerAnimated:YES];
        } failure:^(NSError *error) {
            [SVProgressHUD dismiss];
            [self showAlertWithTitle:@"Error" text:@"Error while siging in, please try again"];
        }];
    }];
}

@end
