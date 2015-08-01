//
//  Settings.h
//  wishbox
//
//  Copyright (c) 2015 Dmitry Mirkitanov. All rights reserved.
//

#import <UIKit/UIKit.h>

#define PRODUCTION_ENV
// #define APPSTORE_SCREENSHOTS
// #define ENABLE_SUBSCRIPTION

UIKIT_EXTERN NSString *const kApiBaseURL;

UIKIT_EXTERN NSString *const kSharedGroupName;

UIKIT_EXTERN NSString *const kSharedKeychainServiceName;
UIKIT_EXTERN NSString *const kSharedKeychainGroupName;

UIKIT_EXTERN NSString *const kSharedDefaultsKeyLoggedIn;
UIKIT_EXTERN NSString *const kSharedDefaultsKeyUserWishlistNeedsRefresh;

UIKIT_EXTERN NSString *const kDefaultsKeyShouldRegisterPushNotifications;
