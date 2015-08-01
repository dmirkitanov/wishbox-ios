//
//  NewAppsService.m
//  wishbox
//
//  Copyright (c) 2015 Dmitry Mirkitanov. All rights reserved.
//

#import "NewAppsService.h"
#import "Settings.h"
#import <UICKeyChainStore/UICKeyChainStore.h>


@interface NewAppsService () <NSURLSessionDelegate, NSURLSessionTaskDelegate>

@property (nonatomic, strong) NSURLSession *urlSession;

@end


@implementation NewAppsService

+ (instancetype)sharedInstance {
    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    
    return sharedInstance;
}

- (NSURLSession *)urlSession {
    return [self createUrlSession];
}

- (NSURLSession *)createUrlSession {
    if (!_urlSession) {
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"com.powerfulbits.wishbox.add-action.session"];
        config.HTTPAdditionalHeaders = @{@"Content-Type": @"application/json"};
        config.sharedContainerIdentifier = kSharedGroupName;
        _urlSession = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];

        NSLog(@"allocated url session");
    }
    
    return _urlSession;
}

- (void)startNewAppRequest:(NSString *)appStoreId country:(NSString *)country {
    NSLog(@"start new app request: %@ %@", appStoreId, country);

    // first, save it to pending apps
    NSUserDefaults *sharedUserDefaults = [[NSUserDefaults alloc] initWithSuiteName:kSharedGroupName];
    NSDictionary *currentPendingNewApps = [sharedUserDefaults dictionaryForKey:@"pendingNewApps"];
    NSMutableDictionary *updatedPendingNewApps = (currentPendingNewApps ? [NSMutableDictionary dictionaryWithDictionary:currentPendingNewApps] : [NSMutableDictionary dictionary]);

    updatedPendingNewApps[appStoreId] = @{@"appStoreId": appStoreId, @"state": @(kPendingNewAppsStateRequestInProgress)};
    
    [sharedUserDefaults setObject:updatedPendingNewApps forKey:@"pendingNewApps"];
    [sharedUserDefaults synchronize];

    // start request
    UICKeyChainStore *keychain = [UICKeyChainStore keyChainStoreWithService:kSharedKeychainServiceName accessGroup:kSharedKeychainGroupName];
    
    NSMutableDictionary *appJsonDict = [NSMutableDictionary dictionary];
    appJsonDict[@"appStoreId"] = appStoreId;
    if (country)
        appJsonDict[@"country"] = country;
    NSDictionary *jsonDict = @{@"app": appJsonDict};
    
    NSString *urlString = [NSString stringWithFormat:@"%@/%@", kApiBaseURL, @"wishlists/mine/apps"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    request.HTTPMethod = @"POST";
    request.HTTPBody = [NSJSONSerialization dataWithJSONObject:jsonDict options:0 error:nil];
    [request setValue:keychain[@"login"] forHTTPHeaderField:@"X-Login" ];
    [request setValue:keychain[@"apiToken"] forHTTPHeaderField:@"X-Api-Token" ];
    
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    NSURLSessionTask *task = [self.urlSession downloadTaskWithRequest:request];
    task.taskDescription = appStoreId;
    
    [task resume];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    NSHTTPURLResponse *response = (NSHTTPURLResponse *)task.response;
    BOOL success = (response.statusCode >= 200 && response.statusCode < 300);
    BOOL recoverable = (response.statusCode >= 500 && response.statusCode < 600) || (response.statusCode == 403);
    
    NSUserDefaults *sharedUserDefaults = [[NSUserDefaults alloc] initWithSuiteName:kSharedGroupName];
    NSDictionary *currentPendingNewApps = [sharedUserDefaults dictionaryForKey:@"pendingNewApps"];
    NSMutableDictionary *updatedPendingNewApps = (currentPendingNewApps ? [NSMutableDictionary dictionaryWithDictionary:currentPendingNewApps] : [NSMutableDictionary dictionary]);

    NSDictionary *pendingNewApp = updatedPendingNewApps[task.taskDescription];
    if (!pendingNewApp) {
        NSLog(@"new app request %@ (app = %@, code %ld), but this app doesn't exist in dict!", (success ? @"completed" : @"failed"), task.taskDescription, (long)response.statusCode);
        return;
    }

    if (!success && recoverable) {
        NSLog(@"new app request failed (app = %@, code %ld), changing state to InQueue ", task.taskDescription, (long)response.statusCode);

        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:pendingNewApp];
        dict[@"state"] = @(kPendingNewAppsStateInQueue);
        dict[@"attempts"] = @(1);
        dict[@"lastAttempt"] = [NSDate date];
        updatedPendingNewApps[task.taskDescription] = dict;
    } else {
        NSLog(@"new app request %@ (app = %@, code %ld), removing it from dict", (success ? @"completed" : @"failed"), task.taskDescription, (long)response.statusCode);

        [updatedPendingNewApps removeObjectForKey:task.taskDescription];
    }

    [sharedUserDefaults setObject:updatedPendingNewApps forKey:@"pendingNewApps"];
    [sharedUserDefaults setBool:YES forKey:kSharedDefaultsKeyUserWishlistNeedsRefresh];
    [sharedUserDefaults synchronize];
}


@end
