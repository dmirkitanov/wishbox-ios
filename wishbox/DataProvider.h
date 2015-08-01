//
//  DataProvider.h
//  wishbox
//
//  Copyright (c) 2015 Dmitry Mirkitanov. All rights reserved.
//

#import <Foundation/Foundation.h>

UIKIT_EXTERN NSString *const kDataProviderNotificationUserUpdated;
UIKIT_EXTERN NSString *const kDataProviderNotificationUserWishlistUpdated;
UIKIT_EXTERN NSString *const kDataProviderNotificationFollowedWishlistsUpdated;

@class User;
@class Wishlist;
@class App;

@interface DataProvider : NSObject

@property (nonatomic, strong, readonly) User *currentUser;
@property (nonatomic, strong, readonly) Wishlist *userWishlist;
@property (nonatomic, strong, readonly) NSMutableDictionary *followedWishlists;

+ (DataProvider *)sharedInstance;

- (void)loadCachedData;
- (void)saveDataToCache;
- (void)clearCachedData;

- (void)updateCurrentUserFromServerWithSuccess:(void (^)(void))successBlock failure:(void (^)(NSError *error))failureBlock;
- (void)updateCurrentUserFromUser:(User *)user;
- (void)loginWithAuthData:(NSDictionary *)authData success:(void (^)())success failure:(void (^)(NSError *error))failure;
- (void)clearCurrentUser;

- (void)updateWishlists;
- (void)updateUserWishlistWithSuccess:(void (^)())successBlock failure:(void (^)(NSError *error))failureBlock;

- (void)loadFollowedWishlist:(NSString *)urlKey success:(void (^)(Wishlist *wishlist))successBlock failure:(void (^)(NSError *error))failureBlock;
- (void)updateFollowedWishlistsWithSuccess:(void (^)())successBlock failure:(void (^)(NSError *error))failureBlock;
- (void)deleteFollowedWishlist:(NSString *)urlKey success:(void (^)())successBlock failure:(void (^)(NSError *error))failureBlock;

- (void)updateLikeState:(BOOL)likeState forFollowedWishlist:(NSString *)urlKey success:(void (^)())successBlock failure:(void (^)(NSError *error))failureBlock;

- (void)deleteWishlistApp:(App *)app success:(void (^)())successBlock failure:(void (^)(NSError *error))failureBlock;

- (void)addApp:(App *)app success:(void (^)())successBlock failure:(void (^)(NSError *error))failureBlock;

- (void)processPendingNewApps;
- (void)updateUserWishlistIfNeeded;

- (void)saveUserToServerWithSuccess:(void (^)())successBlock failure:(void (^)(NSError *error))failureBlock;
- (void)saveUserWishlistToServerWithSuccess:(void (^)())successBlock failure:(void (^)(NSError *error))failureBlock;

@end
