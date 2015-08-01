//
//  LoginViewController.h
//  wishbox
//
//  Copyright (c) 2015 Dmitry Mirkitanov. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FacebookSDK/FacebookSDK.h>

@interface LoginViewController : UIViewController

- (void)facebookSessionStateChanged:(FBSession *)session state:(FBSessionState)state error:(NSError *)error;
- (void)applicationWillResignActive:(UIApplication *)application;

@end
