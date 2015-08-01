//
//  AppDelegate.h
//  wishbox
//
//  Copyright (c) 2015 Dmitry Mirkitanov. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <RestKit/RestKit.h>
#import <FacebookSDK/FacebookSDK.h>
#import "MainViewController.h"
#import "User.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, strong, readonly) MainViewController *mainViewController;
@property (nonatomic, strong, readonly) NSString *appStoreCountry;
@property (nonatomic, strong, readonly) NSArray *countries;

+ (AppDelegate *)instance;

- (void)loginWithAuthData:(NSDictionary *)authData success:(void (^)())success failure:(void (^)(NSError *error))failure;
- (void)logout;

- (void)registerForPushNotifications;
- (void)setShouldRegisterPushNotifications;

@property (nonatomic, readonly, getter=isLoggedIn) BOOL loggedIn;

- (void)facebookSessionStateChanged:(FBSession *)session state:(FBSessionState)state error:(NSError *)error;

- (void)setAppStoreCountry:(NSString *)appStoreCountry;

@end

