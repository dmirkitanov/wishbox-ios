//
//  NewAppsService.h
//  wishbox
//
//  Copyright (c) 2015 Dmitry Mirkitanov. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, PendingNewAppsState) {
    kPendingNewAppsStateRequestInProgress = 0,
    kPendingNewAppsStateInQueue = 1
};


@interface NewAppsService : NSObject

+ (instancetype)sharedInstance;

- (NSURLSession *)createUrlSession;
- (void)startNewAppRequest:(NSString *)appStoreId country:(NSString *)country;

@end
