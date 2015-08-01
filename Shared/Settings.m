//
//  Settings.m
//  wishbox
//
//  Copyright (c) 2015 Dmitry Mirkitanov. All rights reserved.
//

#import "Settings.h"

#ifdef PRODUCTION_ENV
NSString *const kApiBaseURL = @"https://getwishbox.net/api/1";
#else
//NSString *const kApiBaseURL = @"http://192.168.0.107/app_dev.php/api/1";
NSString *const kApiBaseURL = @"https://getwishbox.net/api/1";
#endif

NSString *const kSharedGroupName = @"group.com.powerfulbits.wishbox";

NSString *const kSharedKeychainServiceName = @"wishbox";
NSString *const kSharedKeychainGroupName = @"F9RM747DXW.com.powerfulbits.wishbox";
NSString *const kSharedDefaultsKeyLoggedIn = @"loggedIn";
NSString *const kSharedDefaultsKeyUserWishlistNeedsRefresh = @"userWishlistNeedsRefresh";

NSString *const kDefaultsKeyShouldRegisterPushNotifications = @"shouldRegisterForPushNotifications";

//@interface Settings ()
//@end
//
//@implementation Settings
//@end
