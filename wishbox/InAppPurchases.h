//
//  InAppPurchases.h
//  wishbox
//
//  Copyright (c) 2015 Dmitry Mirkitanov. All rights reserved.
//

#import <Foundation/Foundation.h>

UIKIT_EXTERN NSString *const kInAppPurchasesNotificationProductsLoaded;
UIKIT_EXTERN NSString *const kInAppPurchasesErrorDomain;

NS_ENUM(NSInteger, kInAppPurchasesErrorCode) {
    kInAppPurchasesErrorNoSuchProductIdentifier = 1,
    kInAppPurchasesErrorReceiptNotFound = 2,
    kInAppPurchasesErrorRecoverableServerError = 3,
    kInAppPurchasesErrorPermanentServerError = 4,
    kInAppPurchasesErrorPurchaseCancelled = 5,
    kInAppPurchasesErrorAppStoreError = 6
};

@class SKProduct;

@interface InAppPurchases : NSObject

+ (InAppPurchases *)sharedInstance;

- (void)startObservingTransactions;
- (void)stopObservingTransactions;

- (void)requestProductsWithSuccess:(void (^)(void))successBlock failure:(void (^)(NSError *error))failureBlock;
- (NSString *)getAppStoreCountry;
- (BOOL)isProductIdentifierLoaded:(NSString *)productIdentifier;
- (SKProduct *)productForProductIdentifier:(NSString *)productIdentifier;
- (NSString *)localizedPriceForProductIdentifier:(NSString *)productIdentifier;
- (void)buyProduct:(NSString *)productIdentifier success:(void (^)(void))successBlock failure:(void (^)(NSError *error))failureBlock;

@end
