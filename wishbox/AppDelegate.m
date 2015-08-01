//
//  AppDelegate.m
//  wishbox
//
//  Copyright (c) 2015 Dmitry Mirkitanov. All rights reserved.
//

#import "AppDelegate.h"
#import <Fabric/Fabric.h>
#import <TwitterKit/TwitterKit.h>
#import <Crashlytics/Crashlytics.h>
#import <UICKeyChainStore/UICKeyChainStore.h>
#import <Instabug/Instabug.h>
#import "InAppPurchases.h"
#import "DataProvider.h"
#import "Analytics.h"

#import "User.h"
#import "Wishlist.h"
#import "App.h"

#import "Settings.h"
#import "AppListViewController.h"
#import "NewAppsService.h"

@interface AppDelegate () <NSURLSessionTaskDelegate>

@property (nonatomic, readwrite) BOOL loggedIn;
@property (nonatomic, strong) NSString *pushNotificationsToken;
@property (nonatomic, strong, readwrite) NSString *appStoreCountry;
@property (nonatomic, strong, readwrite) NSArray *countries;

@end

@implementation AppDelegate

+ (AppDelegate *)instance {
    return (AppDelegate *)[UIApplication sharedApplication].delegate;
}

- (MainViewController *)mainViewController {
    return (MainViewController *)self.window.rootViewController;
}

#pragma mark - Lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    application.applicationIconBadgeNumber = 0;

    [[Analytics sharedInstance] initializeAnalytics];
    [self initializeRestKit];
    [self initializeFacebook];
    [self initializeTwitter];
    [self initializeInstabug];
    [self initializeInAppPurchases];
    
    [self setupAppearance];
    [self setupAppStoreCountry];
    
    [self loginFromSavedApiToken];

    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.

    if (self.mainViewController.loginViewController) {
        [self.mainViewController.loginViewController applicationWillResignActive:application];
    }
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
    application.applicationIconBadgeNumber = 0;
    
    [FBAppEvents activateApp];
    
    [[DataProvider sharedInstance] updateUserWishlistIfNeeded];
    [[DataProvider sharedInstance] processPendingNewApps];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)())completionHandler {
    NSLog(@"handleEventsForBackgroundURLSession: URL session: %@", identifier);

    [[NewAppsService sharedInstance] createUrlSession];
    
    completionHandler();
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    [FBSession.activeSession setStateChangeHandler:^(FBSession *session, FBSessionState state, NSError *error) {
        [[AppDelegate instance] facebookSessionStateChanged:session state:state error:error];
    }];
    
    if ([url.scheme isEqualToString:@"wishbox"] || [url.scheme isEqualToString:@"wishboxapp"]) {
        if ([url.pathComponents count] >= 3 && [url.pathComponents[1] isEqualToString:@"wishlist"] && !isEmpty(url.pathComponents[2])) {
            NSString *urlKey = url.pathComponents[2];

            if ([self mainViewController].rootNavigationController) {

                Wishlist *userWishlist = [DataProvider sharedInstance].userWishlist;
                if (userWishlist && !isEmpty(userWishlist.urlKey) && [userWishlist.urlKey isEqualToString:urlKey]) {
                    NSLog(@"switching to wishlist (user): %@", urlKey);
                    [self.mainViewController resetRootNavigationController];
                } else {
                    NSLog(@"switching to wishlist (friend): %@", urlKey);
                    [self.mainViewController resetRootNavigationController];
                    AppListViewController *appListViewController = self.mainViewController.rootNavigationController.viewControllers[0];
                    appListViewController.urlKeyTrigger = urlKey;
                }
                
            }
            return YES;
        }
    }
    
    return [FBAppCall handleOpenURL:url sourceApplication:sourceApplication];
}


#pragma mark - Auth

- (BOOL)isLoggedIn {
    NSUserDefaults *sharedUserDefaults = [[NSUserDefaults alloc] initWithSuiteName:kSharedGroupName];
    return [sharedUserDefaults boolForKey:kSharedDefaultsKeyLoggedIn];
}

- (void)setLoggedIn:(BOOL)loggedIn {
    NSUserDefaults *sharedUserDefaults = [[NSUserDefaults alloc] initWithSuiteName:kSharedGroupName];
    [sharedUserDefaults setBool:loggedIn forKey:kSharedDefaultsKeyLoggedIn];
    [sharedUserDefaults synchronize];
}

- (void)loginFromSavedApiToken {
    if (![self isLoggedIn])
        return;
    
    UICKeyChainStore *keychain = [UICKeyChainStore keyChainStoreWithService:kSharedKeychainServiceName accessGroup:kSharedKeychainGroupName];
    NSString *login = keychain[@"login"];
    NSString *apiToken = keychain[@"apiToken"];

    // set default auth header
    [[RKObjectManager sharedManager].HTTPClient setDefaultHeader:@"X-Login" value:login];
    [[RKObjectManager sharedManager].HTTPClient setDefaultHeader:@"X-Api-Token" value:apiToken];
    
    [[DataProvider sharedInstance] loadCachedData];

    [[DataProvider sharedInstance] updateCurrentUserFromServerWithSuccess:^{
        [[InAppPurchases sharedInstance] startObservingTransactions];
        
        [self registerForPushNotifications];
        
        [[DataProvider sharedInstance] updateWishlists];
    } failure:nil];
}

- (void)loginWithAuthData:(NSDictionary *)authData success:(void (^)())success failure:(void (^)(NSError *error))failure {
    [[DataProvider sharedInstance] loadCachedData];

    [[DataProvider sharedInstance] loginWithAuthData:authData success:^{
        // set default auth header
        [[RKObjectManager sharedManager].HTTPClient setDefaultHeader:@"X-Login" value:[DataProvider sharedInstance].currentUser.login];
        [[RKObjectManager sharedManager].HTTPClient setDefaultHeader:@"X-Api-Token" value:[DataProvider sharedInstance].currentUser.apiToken];
        
        // save apiToken to keychain
        UICKeyChainStore *keychain = [UICKeyChainStore keyChainStoreWithService:kSharedKeychainServiceName accessGroup:kSharedKeychainGroupName];
        keychain[@"login"] = [DataProvider sharedInstance].currentUser.login;
        keychain[@"apiToken"] = [DataProvider sharedInstance].currentUser.apiToken;
        
        self.loggedIn = YES;
        
        [[InAppPurchases sharedInstance] startObservingTransactions];
        
        [self updatePushTokenOnServer];
        
        [[DataProvider sharedInstance] updateWishlists];
        [[DataProvider sharedInstance] processPendingNewApps];

        if (success)
            success();
    } failure:^(NSError *error) {
        if (failure)
            failure(error);
    }];
}

- (void)logout {
    [[InAppPurchases sharedInstance] stopObservingTransactions];
    
    // clear token on the server
    [self deletePushTokenOnServer];
    
    // clear default auth header
    [[RKObjectManager sharedManager].HTTPClient setDefaultHeader:@"X-Login" value:nil];
    [[RKObjectManager sharedManager].HTTPClient setDefaultHeader:@"X-Api-Token" value:nil];
    
    [[DataProvider sharedInstance] clearCachedData];

    [[DataProvider sharedInstance] clearCurrentUser];
    
    // clear apiToken in keychain
    UICKeyChainStore *keychain = [UICKeyChainStore keyChainStoreWithService:kSharedKeychainServiceName accessGroup:kSharedKeychainGroupName];
    keychain[@"login"] = nil;
    keychain[@"apiToken"] = nil;
    
    self.loggedIn = NO;
}

- (void)facebookSessionStateChanged:(FBSession *)session state:(FBSessionState)state error:(NSError *)error {
    if (self.mainViewController.loginViewController) {
        [self.mainViewController.loginViewController facebookSessionStateChanged:session state:state error:error];
    }
    
    if (!error && state == FBSessionStateOpen) {
        DLog(@"facebook session opened");
        return;
    }
    
    if (state == FBSessionStateClosed || state == FBSessionStateClosedLoginFailed) {
        DLog(@"facebook session closed");
    }
    
    if (error) {
        DLog(@"facebook session error: %@", [error description]);

        [FBSession.activeSession closeAndClearTokenInformation];
    }
}


#pragma mark - Services

- (void)initializeTwitter {
    [Fabric with:@[TwitterKit, CrashlyticsKit]];
}

- (void)initializeInstabug {
    [Instabug startWithToken:@"b47f39cbbe1a60cd173d8d3808c563ca" captureSource:IBGCaptureSourceUIKit invocationEvent:IBGInvocationEventShake];

    [Instabug setButtonsFontColor:[UIColor colorWithRed:(255/255.0) green:(255/255.0) blue:(255/255.0) alpha:1.0]];
    [Instabug setButtonsColor:[UIColor colorWithRed:(160/255.0) green:(43/255.0) blue:(43/255.0) alpha:1.0]];
    [Instabug setHeaderFontColor:[UIColor colorWithRed:(255/255.0) green:(255/255.0) blue:(255/255.0) alpha:1.0]];
    [Instabug setHeaderColor:[UIColor colorWithRed:(191/255.0) green:(51/255.0) blue:(23/255.0) alpha:1.0]];
    [Instabug setTextFontColor:[UIColor colorWithRed:(82/255.0) green:(83/255.0) blue:(83/255.0) alpha:1.0]];
    [Instabug setTextBackgroundColor:[UIColor colorWithRed:(249/255.0) green:(249/255.0) blue:(249/255.0) alpha:1.0]];

    [Instabug setEmailPlaceholder:@"Email"];
    [Instabug setCommentPlaceholder:@"Your feedback"];
    
    [Instabug setWillShowStartAlert:NO];
    
    [Instabug setIsTrackingCrashes:NO];
    [Instabug setIsTrackingUserSteps:NO];
}

- (void)initializeFacebook {
    if (FBSession.activeSession.state == FBSessionStateCreatedTokenLoaded) {
        [FBSession openActiveSessionWithReadPermissions:@[@"public_profile"] allowLoginUI:NO completionHandler:^(FBSession *session, FBSessionState state, NSError *error) {
            [self facebookSessionStateChanged:session state:state error:error];
        }];
    }
}

- (void)initializeRestKit {
    RKObjectManager *objectManager = [RKObjectManager managerWithBaseURL:[NSURL URLWithString:kApiBaseURL]];
    [RKObjectManager setSharedManager:objectManager];

    // User class
    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[User class]];
    [userMapping addAttributeMappingsFromArray:@[@"login", @"apiToken", @"name", @"accountType", @"subscriptionExpiresAt", @"email", @"appStoreCountry"]];

    [objectManager addResponseDescriptor:[RKResponseDescriptor responseDescriptorWithMapping:userMapping method:RKRequestMethodAny pathPattern:@"users" keyPath:@"user" statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)]];
    [objectManager addResponseDescriptor:[RKResponseDescriptor responseDescriptorWithMapping:userMapping method:RKRequestMethodAny pathPattern:@"users/mine" keyPath:@"user" statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)]];
    [objectManager addResponseDescriptor:[RKResponseDescriptor responseDescriptorWithMapping:userMapping method:RKRequestMethodAny pathPattern:@"purchases" keyPath:@"user" statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)]];

    // App class
    RKObjectMapping *appMapping = [RKObjectMapping mappingForClass:[App class]];
    [appMapping addAttributeMappingsFromArray:@[@"appId", @"appStoreId", @"name", @"category", @"iconUrl", @"price", @"formattedPrice", @"prevPrice", @"prevFormattedPrice"]];

    // Wishlist class
    RKObjectMapping *wishlistMapping = [RKObjectMapping mappingForClass:[Wishlist class]];
    [wishlistMapping addAttributeMappingsFromArray:@[@"name", @"liked", @"enabled", @"likesCount", @"urlKey", @"shareUrl"]];
    [wishlistMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"apps" toKeyPath:@"apps" withMapping:appMapping]];
    
    [objectManager addResponseDescriptor:[RKResponseDescriptor responseDescriptorWithMapping:wishlistMapping method:RKRequestMethodAny pathPattern:@"wishlists" keyPath:@"mine" statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)]];
    [objectManager addResponseDescriptor:[RKResponseDescriptor responseDescriptorWithMapping:wishlistMapping method:RKRequestMethodAny pathPattern:@"wishlists" keyPath:@"followed" statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)]];
    [objectManager addResponseDescriptor:[RKResponseDescriptor responseDescriptorWithMapping:wishlistMapping method:RKRequestMethodAny pathPattern:@"wishlists/mine" keyPath:@"mine" statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)]];
    [objectManager addResponseDescriptor:[RKResponseDescriptor responseDescriptorWithMapping:wishlistMapping method:RKRequestMethodAny pathPattern:@"wishlists/followed" keyPath:@"followed" statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)]];
    [objectManager addResponseDescriptor:[RKResponseDescriptor responseDescriptorWithMapping:wishlistMapping method:RKRequestMethodAny pathPattern:@"wishlists/followed/:urlKey" keyPath:@"wishlist" statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)]];
}

- (void)initializeInAppPurchases {
#ifdef ENABLE_SUBSCRIPTION
    [[InAppPurchases sharedInstance] requestProductsWithSuccess:nil failure:nil];
#endif
}


#pragma mark - Setup

- (void)setupAppStoreCountry {
    self.countries = [[NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"countries" ofType:@"plist"]] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"cname" ascending:YES]]];

#ifdef APPSTORE_SCREENSHOTS
    self.appStoreCountry = @"US";
#else
    self.appStoreCountry = [[NSUserDefaults standardUserDefaults] stringForKey:@"appStoreCountry"];
    if (isEmpty(self.appStoreCountry)) {
        self.appStoreCountry = @"US";        // fallback
    }
    
    [[NSNotificationCenter defaultCenter] addObserverForName:kInAppPurchasesNotificationProductsLoaded object:nil queue:nil usingBlock:^(NSNotification *notification) {
        if (notification.userInfo[@"error"])
            return;
        
        NSString *appStoreCountry = [[InAppPurchases sharedInstance] getAppStoreCountry];
        [[NSUserDefaults standardUserDefaults] setObject:appStoreCountry forKey:@"appStoreCountry"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        if (![appStoreCountry isEqualToString:self.appStoreCountry]) {
            self.appStoreCountry = appStoreCountry;
            [self updatePushTokenOnServer];
        }
    }];
#endif
}

- (void)setAppStoreCountry:(NSString *)appStoreCountry {
    _appStoreCountry = appStoreCountry;
    [[NSUserDefaults standardUserDefaults] setObject:appStoreCountry forKey:@"appStoreCountry"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setupAppearance {
    [UINavigationBar appearance].barTintColor = UIColorFromRGB(0xBF3317);
    [UINavigationBar appearance].tintColor = [UIColor whiteColor];
    [UINavigationBar appearance].titleTextAttributes = @{NSFontAttributeName: [UIFont fontWithName:@"OpenSans-Semibold" size:18],
                                                         NSForegroundColorAttributeName: [UIColor whiteColor]};
}


#pragma mark - Push notifications

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    const unsigned *tokenBytes = [deviceToken bytes];
    NSString *hexToken = [NSString stringWithFormat:@"%08x%08x%08x%08x%08x%08x%08x%08x",
                          ntohl(tokenBytes[0]), ntohl(tokenBytes[1]), ntohl(tokenBytes[2]),
                          ntohl(tokenBytes[3]), ntohl(tokenBytes[4]), ntohl(tokenBytes[5]),
                          ntohl(tokenBytes[6]), ntohl(tokenBytes[7])];
    
    NSLog(@"PUSH: Successfully registered. The token is: [%@]", hexToken);
    
    self.pushNotificationsToken = hexToken;
    
    [self updatePushTokenOnServer];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    NSLog(@"PUSH: Failed to register due to error: [%@]", [error localizedDescription]);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    NSLog(@"didReceiveRemoteNotification: %@", [userInfo description]);

    // TODO: call updateWishlist, show alert window?
    //    UIApplicationState state = [application applicationState];
    //    if (state == UIApplicationStateActive) { } else { }
}

- (void)setShouldRegisterPushNotifications {
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kDefaultsKeyShouldRegisterPushNotifications];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)registerForPushNotifications {
#ifdef ENABLE_SUBSCRIPTION
    BOOL shouldRegisterPushNotifications = [[NSUserDefaults standardUserDefaults] boolForKey:kDefaultsKeyShouldRegisterPushNotifications];
    
    if (!shouldRegisterPushNotifications) {
        DLog(@"skipping registration for push notificationsToken");
        return;
    }
    
    DLog(@"registering for push notificationsToken");
    
    UIUserNotificationType userNotificationTypes = (UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound);
    UIUserNotificationSettings *notificationSettings = [UIUserNotificationSettings settingsForTypes:userNotificationTypes categories:nil];
    [[UIApplication sharedApplication] registerUserNotificationSettings:notificationSettings];
    [[UIApplication sharedApplication] registerForRemoteNotifications];
#endif
}

- (void)updatePushTokenOnServer {
    if (!self.pushNotificationsToken) {
        DLog(@"pushNotificationsToken is not set, skipping update");
        return;
    }
    
    if (!self.loggedIn) {
        DLog(@"not logged in, skipping update");
        return;
    }

    NSDictionary *tokenParams = @{@"token": self.pushNotificationsToken,
                                  @"country": self.appStoreCountry,
                                  @"lang": [[NSLocale preferredLanguages] objectAtIndex:0]};
    
    NSDictionary *savedTokenParams = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"pushNotificationsTokenParams"];
    
    if ([tokenParams isEqual:savedTokenParams]) {
        DLog(@"tokenParams are equal, skipping update");
        return;
    }
    
    DLog(@"tokenParams are different, performing update");
    
    [[RKObjectManager sharedManager] postObject:nil path:@"push_tokens" parameters:@{@"pushToken": tokenParams} success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [[NSUserDefaults standardUserDefaults] setObject:tokenParams forKey:@"pushNotificationsTokenParams"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        });
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            // TODO: could do something with the error
        });
    }];
}

- (void)deletePushTokenOnServer {
    NSDictionary *savedTokenParams = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"pushNotificationsTokenParams"];
    
    if (!savedTokenParams || isEmpty(savedTokenParams[@"token"])) {
        DLog(@"pushNotificationsToken is not set, skipping delete");
        return;
    }
    
    DLog(@"performing delete");
    
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"pushNotificationsTokenParams"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    NSString *deletePath = [NSString stringWithFormat:@"push_tokens/%@", savedTokenParams[@"token"]];
    [[RKObjectManager sharedManager] deleteObject:nil path:deletePath parameters:nil success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        dispatch_async(dispatch_get_main_queue(), ^{
        });
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
        });
    }];
}

@end
