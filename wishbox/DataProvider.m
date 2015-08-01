//
//  DataProvider.m
//  wishbox
//
//  Copyright (c) 2015 Dmitry Mirkitanov. All rights reserved.
//

#import "DataProvider.h"
#import "AppDelegate.h"
#import "Wishlist.h"
#import "App.h"
#import "Settings.h"
#import "NewAppsService.h"

NSString *const kDataProviderNotificationUserUpdated = @"com.powerfulbits.wishbox.notification.DataProvider.UserUpdated";
NSString *const kDataProviderNotificationUserWishlistUpdated = @"com.powerfulbits.wishbox.notification.DataProvider.UserWishlistUpdated";
NSString *const kDataProviderNotificationFollowedWishlistsUpdated = @"com.powerfulbits.wishbox.notification.DataProvider.FollowedWishlistsUpdated";

@interface DataProvider ()

@property (nonatomic, strong, readwrite) User *currentUser;
@property (nonatomic, strong, readwrite) Wishlist *userWishlist;
@property (nonatomic, strong, readwrite) NSMutableDictionary *followedWishlists;

@property (nonatomic, strong, readonly) NSString *userCacheFile;
@property (nonatomic, strong, readonly) NSString *userWishlistCacheFile;
@property (nonatomic, strong, readonly) NSString *followedWishlistsCacheFile;

@end

@implementation DataProvider

@synthesize userCacheFile = _userCacheFile;
@synthesize userWishlistCacheFile = _userWishlistCacheFile;
@synthesize followedWishlistsCacheFile = _followedWishlistsCacheFile;

+ (DataProvider *)sharedInstance {
    static dispatch_once_t once;
    static DataProvider *sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    
    return sharedInstance;
}

- (instancetype)init {
    if ((self = [super init])) {
        self.followedWishlists = [NSMutableDictionary dictionary];
        self.userWishlist = nil;
    }
    return self;
}

#pragma mark - Data cache

- (NSString *)userCacheFile {
    if (_userCacheFile)
        return _userCacheFile;
    
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    
    _userCacheFile = [documentsPath stringByAppendingPathComponent:@"user.plist"];
    
    return _userCacheFile;
}

- (NSString *)userWishlistCacheFile {
    if (_userWishlistCacheFile)
        return _userWishlistCacheFile;
    
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    
    _userWishlistCacheFile = [documentsPath stringByAppendingPathComponent:@"userWishlist.plist"];
    
    return _userWishlistCacheFile;
}

- (NSString *)followedWishlistsCacheFile {
    if (_followedWishlistsCacheFile)
        return _followedWishlistsCacheFile;
    
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    
    _followedWishlistsCacheFile = [documentsPath stringByAppendingPathComponent:@"followedWishlists.plist"];
    
    return _followedWishlistsCacheFile;
}

- (void)loadCachedData {
    self.currentUser = [NSKeyedUnarchiver unarchiveObjectWithFile:self.userCacheFile];
    if (!self.currentUser) {
        self.currentUser = [[User alloc] init];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:kDataProviderNotificationUserUpdated object:self];
    
    self.userWishlist = [NSKeyedUnarchiver unarchiveObjectWithFile:self.userWishlistCacheFile];
    if (!self.userWishlist) {
        self.userWishlist = [[Wishlist alloc] init];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:kDataProviderNotificationUserWishlistUpdated object:self];

    NSDictionary *followedWishlists = [NSKeyedUnarchiver unarchiveObjectWithFile:self.followedWishlistsCacheFile];
    if (followedWishlists) {
        self.followedWishlists = [NSMutableDictionary dictionaryWithDictionary:followedWishlists];
        [[NSNotificationCenter defaultCenter] postNotificationName:kDataProviderNotificationFollowedWishlistsUpdated object:self];
    }
}

- (void)saveDataToCache {
    BOOL res1 = [NSKeyedArchiver archiveRootObject:self.currentUser toFile:self.userCacheFile];
    if (!res1) {
        DLog(@"cannot save user to cache file!");
    }
    
    BOOL res2 = [NSKeyedArchiver archiveRootObject:self.userWishlist toFile:self.userWishlistCacheFile];
    if (!res2) {
        DLog(@"cannot save user wishlist to cache file!");
    }
    
    BOOL res3 = [NSKeyedArchiver archiveRootObject:self.followedWishlists toFile:self.followedWishlistsCacheFile];
    if (!res3) {
        DLog(@"cannot save followed wishlists to cache file!");
    }
}

- (void)clearCachedData {
    [[NSFileManager defaultManager] removeItemAtPath:self.userCacheFile error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:self.userWishlistCacheFile error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:self.followedWishlistsCacheFile error:nil];
}

#pragma mark - Data loading
#pragma mark User

- (void)updateCurrentUserFromServerWithSuccess:(void (^)(void))successBlock failure:(void (^)(NSError *error))failureBlock {
    [[RKObjectManager sharedManager] getObject:nil path:@"users/mine" parameters:nil success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        dispatch_async(dispatch_get_main_queue(), ^{
            User *user = mappingResult.firstObject;
            self.currentUser = user;
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kDataProviderNotificationUserUpdated object:self];
            
            DLog(@"user.exp: %@", [user.subscriptionExpiresAt description]);
            
            if (successBlock)
                successBlock();
        });
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (operation.HTTPRequestOperation.response.statusCode == 403) {
                NSLog(@"Api Key is invalid, performing logout");
                
                [[AppDelegate instance] logout];
                [[AppDelegate instance].mainViewController switchToLoginControllerAnimated:YES];
            }
            
            if (failureBlock)
                failureBlock(error);
        });
    }];
}

- (void)updateCurrentUserFromUser:(User *)user {
    self.currentUser = user;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kDataProviderNotificationUserUpdated object:self];
}

- (void)loginWithAuthData:(NSDictionary *)authData success:(void (^)())success failure:(void (^)(NSError *error))failure {
    [[RKObjectManager sharedManager] postObject:nil path:@"users" parameters:@{@"authData": authData} success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"login successful");

            User *user = mappingResult.firstObject;
            self.currentUser = user;

            if (success)
                success();
        });
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"login failed: %@, %@, %@", error, operation.HTTPRequestOperation.response, operation.HTTPRequestOperation.responseString);
            
            if (failure)
                failure(error);
        });
    }];
}

- (void)clearCurrentUser {
    self.currentUser = nil;
}

#pragma mark Wishlists

- (void)updateWishlists {
    if (![AppDelegate instance].loggedIn)
        return;
    
    [self resetUserWishlistNeedsRefresh];
    
    NSDictionary *params = @{@"country": [AppDelegate instance].appStoreCountry};
    [[RKObjectManager sharedManager] getObject:nil path:@"wishlists" parameters:params success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        dispatch_async(dispatch_get_main_queue(), ^{
            // mine
            self.userWishlist = mappingResult.dictionary[@"mine"];
            [[NSNotificationCenter defaultCenter] postNotificationName:kDataProviderNotificationUserWishlistUpdated object:self];
            
            // followed
            NSMutableDictionary *followedWishlists = [NSMutableDictionary dictionary];
            for (Wishlist *wishlist in mappingResult.dictionary[@"followed"]) {
                followedWishlists[wishlist.urlKey] = wishlist;
            }
            self.followedWishlists = followedWishlists;
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kDataProviderNotificationFollowedWishlistsUpdated object:self];
            
            // save to cache
            [self saveDataToCache];
        });
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
        });
    }];
}

- (void)resetUserWishlistNeedsRefresh {
    NSUserDefaults *sharedUserDefaults = [[NSUserDefaults alloc] initWithSuiteName:kSharedGroupName];
    [sharedUserDefaults setBool:NO forKey:kSharedDefaultsKeyUserWishlistNeedsRefresh];
    [sharedUserDefaults synchronize];
}

- (void)updateUserWishlistIfNeeded {
    NSUserDefaults *sharedUserDefaults = [[NSUserDefaults alloc] initWithSuiteName:kSharedGroupName];
    BOOL userWishlistNeedsRefresh = [sharedUserDefaults boolForKey:kSharedDefaultsKeyUserWishlistNeedsRefresh];
    if (!userWishlistNeedsRefresh)
        return;
    
    [self updateUserWishlistWithSuccess:nil failure:nil];
}

- (void)updateUserWishlistWithSuccess:(void (^)())successBlock failure:(void (^)(NSError *error))failureBlock {
    if (![AppDelegate instance].loggedIn)
        return;
    
    [self resetUserWishlistNeedsRefresh];
    
    NSDictionary *params = @{@"country": [AppDelegate instance].appStoreCountry};
    [[RKObjectManager sharedManager] getObject:nil path:@"wishlists/mine" parameters:params success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        dispatch_async(dispatch_get_main_queue(), ^{
            
            self.userWishlist = mappingResult.firstObject;
            [self saveDataToCache];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kDataProviderNotificationUserWishlistUpdated object:self];
            
            if (successBlock)
                successBlock();
        });
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (failureBlock)
                failureBlock(error);
        });
    }];
}


- (void)updateFollowedWishlistsWithSuccess:(void (^)())successBlock failure:(void (^)(NSError *error))failureBlock {
    if (![AppDelegate instance].loggedIn) {
        if (failureBlock)
            failureBlock(nil);
        return;
    }
    
    NSDictionary *params = @{@"country": [AppDelegate instance].appStoreCountry};
    [[RKObjectManager sharedManager] getObject:nil path:@"wishlists/followed" parameters:params success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        dispatch_async(dispatch_get_main_queue(), ^{
            
            NSMutableDictionary *followedWishlists = [NSMutableDictionary dictionary];
            for (Wishlist *wishlist in mappingResult.dictionary[@"followed"]) {
                followedWishlists[wishlist.urlKey] = wishlist;
            }
            self.followedWishlists = followedWishlists;
            
            [self saveDataToCache];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kDataProviderNotificationFollowedWishlistsUpdated object:self];
            
            if (successBlock)
                successBlock();
        });
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (failureBlock)
                failureBlock(error);
        });
    }];
}

- (void)loadFollowedWishlist:(NSString *)urlKey success:(void (^)(Wishlist *wishlist))successBlock failure:(void (^)(NSError *error))failureBlock {
    if (![AppDelegate instance].loggedIn) {
        if (failureBlock)
            failureBlock(nil);
        return;
    }
    
    NSString *path = [NSString stringWithFormat:@"wishlists/followed/%@", urlKey];
    NSDictionary *params = @{@"country": [AppDelegate instance].appStoreCountry};
    [[RKObjectManager sharedManager] getObject:nil path:path parameters:params success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        dispatch_async(dispatch_get_main_queue(), ^{
            
            Wishlist *wishlist = mappingResult.firstObject;
            
            self.followedWishlists[urlKey] = wishlist;
            [self saveDataToCache];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kDataProviderNotificationFollowedWishlistsUpdated object:self];
            
            if (successBlock)
                successBlock(wishlist);
        });
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (failureBlock)
                failureBlock(error);
        });
    }];
}

- (void)deleteFollowedWishlist:(NSString *)urlKey success:(void (^)())successBlock failure:(void (^)(NSError *error))failureBlock {
    if (![AppDelegate instance].loggedIn) {
        if (failureBlock)
            failureBlock(nil);
        return;
    }
    
    Wishlist *wishlist = self.followedWishlists[urlKey];
    if (!wishlist) {
        if (failureBlock)
            failureBlock(nil);
        return;
    }

    [self.followedWishlists removeObjectForKey:urlKey];
    
    NSString *path = [NSString stringWithFormat:@"wishlists/followed/%@", urlKey];
    [[RKObjectManager sharedManager] deleteObject:nil path:path parameters:nil success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self saveDataToCache];
            [[NSNotificationCenter defaultCenter] postNotificationName:kDataProviderNotificationFollowedWishlistsUpdated object:self];
            if (successBlock)
                successBlock();
        });
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.followedWishlists[urlKey] = wishlist;
            [[NSNotificationCenter defaultCenter] postNotificationName:kDataProviderNotificationFollowedWishlistsUpdated object:self];
            if (failureBlock)
                failureBlock(error);
        });
    }];
}

- (void)updateLikeState:(BOOL)likeState forFollowedWishlist:(NSString *)urlKey success:(void (^)())successBlock failure:(void (^)(NSError *error))failureBlock {
    if (![AppDelegate instance].loggedIn) {
        if (failureBlock)
            failureBlock(nil);
        return;
    }
    
    Wishlist *wishlist = self.followedWishlists[urlKey];
    if (!wishlist) {
        if (failureBlock)
            failureBlock(nil);
        return;
    }
    
    if ([wishlist.liked boolValue] == likeState) {
        if (successBlock)
            successBlock();
        return;
    }
    
    wishlist.liked = @(likeState);
    [[NSNotificationCenter defaultCenter] postNotificationName:kDataProviderNotificationFollowedWishlistsUpdated object:self];
    
    void (^requestSuccessBlock)(RKObjectRequestOperation *, RKMappingResult *) = ^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self saveDataToCache];
            if (successBlock)
                successBlock();
        });
    };
    
    void (^requestFailureBlock)(RKObjectRequestOperation *, NSError *) = ^(RKObjectRequestOperation *operation, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            wishlist.liked = @(!likeState);
            [[NSNotificationCenter defaultCenter] postNotificationName:kDataProviderNotificationFollowedWishlistsUpdated object:self];
            if (failureBlock)
                failureBlock(error);
        });
    };

    NSString *path = [NSString stringWithFormat:@"wishlists/followed/%@/likes", urlKey];
    if (likeState) {
        [[RKObjectManager sharedManager] postObject:nil path:path parameters:nil success:requestSuccessBlock failure:requestFailureBlock];
    } else {
        [[RKObjectManager sharedManager] deleteObject:nil path:path parameters:nil success:requestSuccessBlock failure:requestFailureBlock];
    }
}

- (void)deleteWishlistApp:(App *)app success:(void (^)())successBlock failure:(void (^)(NSError *error))failureBlock {
    if (![AppDelegate instance].loggedIn) {
        if (failureBlock)
            failureBlock(nil);
        return;
    }
    
    NSMutableArray *newApps = [NSMutableArray arrayWithArray:self.userWishlist.apps];
    [newApps removeObject:app];
    self.userWishlist.apps = [NSArray arrayWithArray:newApps];
    
    NSString *path = [NSString stringWithFormat:@"wishlists/mine/apps/%@", app.appId];
    [[RKObjectManager sharedManager] deleteObject:nil path:path parameters:nil success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self saveDataToCache];
            [[NSNotificationCenter defaultCenter] postNotificationName:kDataProviderNotificationUserWishlistUpdated object:self];
            if (successBlock)
                successBlock();
        });
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            
            // insert the app back, search for it first
            BOOL found = NO;
            for (App *existingApp in self.userWishlist.apps) {
                if ([existingApp.appId isEqualToString:app.appId])
                    found = YES;
            }
            if (!found) {
                NSMutableArray *newApps = [NSMutableArray arrayWithArray:self.userWishlist.apps];
                [newApps addObject:app];
                self.userWishlist.apps = [NSArray arrayWithArray:newApps];
                [[NSNotificationCenter defaultCenter] postNotificationName:kDataProviderNotificationUserWishlistUpdated object:self];
            }
            
            if (failureBlock)
                failureBlock(error);
        });
    }];
}

- (void)addApp:(App *)app success:(void (^)())successBlock failure:(void (^)(NSError *error))failureBlock {
    if (![AppDelegate instance].loggedIn) {
        if (failureBlock)
            failureBlock(nil);
        return;
    }

    NSDictionary *jsonDict = @{@"app": @{@"appStoreId": app.appStoreId, @"country": [AppDelegate instance].appStoreCountry}};
    [[RKObjectManager sharedManager] postObject:nil path:@"wishlists/mine/apps" parameters:jsonDict success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        dispatch_async(dispatch_get_main_queue(), ^{
            BOOL found = NO;
            for (App *userApp in self.userWishlist.apps) {
                if ([userApp.appId isEqualToString:app.appId]) {
                    found = YES;
                    break;
                }
            }
            if (!found) {
                NSMutableArray *apps = [NSMutableArray arrayWithArray:self.userWishlist.apps];
                [apps addObject:app];
                self.userWishlist.apps = [NSArray arrayWithArray:apps];
                [[NSNotificationCenter defaultCenter] postNotificationName:kDataProviderNotificationUserWishlistUpdated object:self];
            }
            
            [self updateUserWishlistWithSuccess:nil failure:nil];
            
            if (successBlock)
                successBlock();
        });
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (failureBlock)
                failureBlock(error);
        });
    }];
}

#pragma mark - Pengind new apps processing

- (void)processPendingNewApps {
    DLog(@"starting processPendingNewApps");
    [self processNextPendingNewApp:NO];
}

- (void)processNextPendingNewApp:(BOOL)appsUpdatedOnServer {
    NSUserDefaults *sharedUserDefaults = [[NSUserDefaults alloc] initWithSuiteName:kSharedGroupName];
    NSDictionary *currentPendingNewApps = [sharedUserDefaults dictionaryForKey:@"pendingNewApps"];
    if (!currentPendingNewApps) {
        DLog(@"no processPendingNewApps in queue (no dict found)");
        if (appsUpdatedOnServer) {
            [self updateUserWishlistWithSuccess:nil failure:nil];
        }
        return;
    }
    
    NSMutableDictionary *updatedPendingNewApps = (currentPendingNewApps ? [NSMutableDictionary dictionaryWithDictionary:currentPendingNewApps] : [NSMutableDictionary dictionary]);
    
    NSDictionary *nextPendingNewApp = nil;
    
    for (NSDictionary *pendingNewApp in [updatedPendingNewApps allValues]) {
        if ([pendingNewApp[@"state"] integerValue] == kPendingNewAppsStateInQueue &&
            [[NSDate date] timeIntervalSinceDate:pendingNewApp[@"lastAttempt"]] > 60) {
            // found one
            nextPendingNewApp = pendingNewApp;
            break;
        }
    }
    
    if (!nextPendingNewApp) {
        // no more apps to process
        DLog(@"no processPendingNewApps in queue (no apps with InQueue state and lastAttempt)");
        if (appsUpdatedOnServer) {
            [self updateUserWishlistWithSuccess:nil failure:nil];
        }
        return;
    }
    
    // found app, make query
    DLog(@"found app in processPendingNewApps, making query");

    NSDictionary *jsonDict = @{@"app": @{@"appStoreId": nextPendingNewApp[@"appStoreId"], @"country": [AppDelegate instance].appStoreCountry}};
    [[RKObjectManager sharedManager] postObject:nil path:@"wishlists/mine/apps" parameters:jsonDict success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        dispatch_async(dispatch_get_main_queue(), ^{
            DLog(@"processPendingNewApps query success");
            
            // added, remove it from queue
            [updatedPendingNewApps removeObjectForKey:nextPendingNewApp[@"appStoreId"]];
            
            [sharedUserDefaults setObject:updatedPendingNewApps forKey:@"pendingNewApps"];
            [sharedUserDefaults synchronize];
            
            [self processNextPendingNewApp:YES];
        });
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            DLog(@"processPendingNewApps query error, code=%ld", operation.HTTPRequestOperation.response.statusCode);
            
            if (operation.HTTPRequestOperation.response.statusCode >= 500 || operation.HTTPRequestOperation.response.statusCode == 403) {
                // temp error
                
                if ([nextPendingNewApp[@"attempts"] integerValue] >= 4) {
                    [updatedPendingNewApps removeObjectForKey:nextPendingNewApp[@"appStoreId"]];

                    DLog(@"processPendingNewApps: maximum number of attempts (%ld) for app %@, removing from dict", [nextPendingNewApp[@"attempts"] integerValue], nextPendingNewApp[@"appStoreId"]);
                } else {
                    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:nextPendingNewApp];
                    dict[@"attempts"] = @([dict[@"attempts"] integerValue] + 1);
                    dict[@"lastAttempt"] = [NSDate date];
                    updatedPendingNewApps[dict[@"appStoreId"]] = dict;

                    DLog(@"processPendingNewApps: attempt (%ld) for app %@", [dict[@"attempts"] integerValue], dict[@"appStoreId"]);
                }
                
                [sharedUserDefaults setObject:updatedPendingNewApps forKey:@"pendingNewApps"];
                [sharedUserDefaults synchronize];
                
                [self processNextPendingNewApp:appsUpdatedOnServer];
            } else {
                // perm error
                
                [updatedPendingNewApps removeObjectForKey:nextPendingNewApp[@"appStoreId"]];
                
                [sharedUserDefaults setObject:updatedPendingNewApps forKey:@"pendingNewApps"];
                [sharedUserDefaults synchronize];
                
                [self processNextPendingNewApp:appsUpdatedOnServer];
            }
        });
    }];
}

- (void)saveUserToServerWithSuccess:(void (^)())successBlock failure:(void (^)(NSError *error))failureBlock {
    NSString *name = self.currentUser.name;
    NSString *email = self.currentUser.email;
    NSString *appStoreCountry = self.currentUser.appStoreCountry;
    if (!name && !email && !appStoreCountry) {
        // name is empty, probably logout is in progress
        if (successBlock)
            successBlock();

        return;
    }
    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    if (name)
        params[@"name"] = name;
    if (email)
        params[@"email"] = email;
    if (appStoreCountry)
        params[@"appStoreCountry"] = appStoreCountry;

    [[RKObjectManager sharedManager] putObject:nil path:@"users/mine" parameters:params success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self saveDataToCache];
            if (successBlock)
                successBlock();
        });
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (failureBlock)
                failureBlock(error);
        });
    }];
}

- (void)saveUserWishlistToServerWithSuccess:(void (^)())successBlock failure:(void (^)(NSError *error))failureBlock {
    NSDictionary *params = @{@"enabled": self.userWishlist.enabled};
    [[RKObjectManager sharedManager] putObject:nil path:@"wishlists/mine" parameters:params success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self saveDataToCache];
            if (successBlock)
                successBlock();
        });
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (failureBlock)
                failureBlock(error);
        });
    }];
}

@end
