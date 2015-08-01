//
//  InAppPurchases.m
//  wishbox
//
//  Copyright (c) 2015 Dmitry Mirkitanov. All rights reserved.
//

#import "InAppPurchases.h"
#import <StoreKit/StoreKit.h>
#import <RestKit/RestKit.h>
#import "Analytics.h"
#import "AppDelegate.h"
#import "DataProvider.h"

NSString *const kInAppPurchasesNotificationProductsLoaded = @"com.powerfulbits.wishbox.notification.ProductsLoaded";
NSString *const kInAppPurchasesErrorDomain = @"com.powerfulbits.wishbox.error.InAppPurchases";

@interface InAppPurchases () <SKProductsRequestDelegate, SKPaymentTransactionObserver>

@property (nonatomic, strong) SKProductsRequest *productsRequest;
@property (nonatomic, strong, readwrite) NSArray *products;

@property (nonatomic, strong) NSMutableArray *requestDelegates;
@property (nonatomic, strong) NSMutableDictionary *transactionDelegates;

@end

@implementation InAppPurchases

+ (InAppPurchases *)sharedInstance {
    static dispatch_once_t once;
    static InAppPurchases *sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    
    return sharedInstance;
}

- (instancetype)init {
    if ((self = [super init])) {
        self.requestDelegates = [NSMutableArray array];
        self.transactionDelegates = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)startObservingTransactions {
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
}

- (void)stopObservingTransactions {
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
}

#pragma mark - Products

- (void)requestProductsWithSuccess:(void (^)(void))successBlock failure:(void (^)(NSError *error))failureBlock {
    if (successBlock || failureBlock) {
        NSMutableDictionary *delegates = [NSMutableDictionary dictionaryWithCapacity:2];
        
        if (successBlock)
            delegates[@"success"] = successBlock;
        
        if (successBlock)
            delegates[@"failure"] = failureBlock;
        
        [self.requestDelegates addObject:delegates];
    }
    
    if (self.productsRequest) {
        DLog(@"[In-App Purchases] AppStore products request is already running");
        return;
    }
    
    NSSet *productsIdentifiers = [NSSet setWithArray:@[@"notifications.12m"]];
    DLog(@"[In-App Purchases] AppStore products request for: %@", productsIdentifiers);
    
    self.productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:productsIdentifiers];
    self.productsRequest.delegate = self;
    [self.productsRequest start];
}

- (BOOL)isProductIdentifierLoaded:(NSString *)productIdentifier {
    return ([self productForProductIdentifier:productIdentifier] != nil);
}

- (SKProduct *)productForProductIdentifier:(NSString *)productIdentifier {
    for (SKProduct *product in self.products) {
        if ([product.productIdentifier isEqualToString:productIdentifier])
            return product;
    }
    
    return nil;
}

- (NSString *)localizedPriceForProductIdentifier:(NSString *)productIdentifier {
    for (SKProduct *product in self.products) {
        if ([product.productIdentifier isEqualToString:productIdentifier]) {
            NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
            [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
            [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
            [numberFormatter setLocale:product.priceLocale];
            
            return [numberFormatter stringFromNumber:product.price];
        }
    }
    
    return nil;
}

- (NSString *)getAppStoreCountry {
    NSString *appStoreCountry = nil;
    
    for (SKProduct *product in self.products) {
        NSLocale *storeLocale = product.priceLocale;
        appStoreCountry = (NSString *)CFLocaleGetValue((CFLocaleRef)storeLocale, kCFLocaleCountryCode);
        
        if (!isEmpty(appStoreCountry)) {
            DLog(@"[In-App Purchases] AppStore Country (from product) = %@", appStoreCountry);
            return appStoreCountry;
        }
    }
    
    // If product request didn't work, fallback to user's device locale
    CFLocaleRef userLocaleRef = CFLocaleCopyCurrent();
    appStoreCountry = (NSString *)CFLocaleGetValue(userLocaleRef, kCFLocaleCountryCode);

    DLog(@"AppStore Country (from current locale) = %@", appStoreCountry);
    return appStoreCountry;
}

#pragma mark - SKProductsRequestDelegate

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    dispatch_async(dispatch_get_main_queue(), ^{
        DLog(@"[In-App Purchases] Products list:");
        
        for (SKProduct *product in response.products) {
            DLog(@"[In-App Purchases] Found product: %@ %@ %0.2f", product.productIdentifier, product.localizedTitle, product.price.floatValue);
        }
        
        self.products = response.products;
        
        for (NSString *invalidProductId in response.invalidProductIdentifiers) {
            DLog(@"[In-App Purchases] Invalid product id: %@" , invalidProductId);
        }
    });
}

- (void)requestDidFinish:(SKRequest *)request {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (request != self.productsRequest) {
            DLog(@"[In-App Purchases] WARNING: unexpected request encountered");
            return;
        }
        
        DLog(@"[In-App Purchases] Products loaded");
        
        for (NSDictionary *delegates in self.requestDelegates) {
            void (^successBlock)(void) = delegates[@"success"];
            successBlock();
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kInAppPurchasesNotificationProductsLoaded object:self];
        
        [self.requestDelegates removeAllObjects];
        self.productsRequest = nil;
    });
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (request != self.productsRequest) {
            DLog(@"[In-App Purchases] WARNING: unexpected request encountered");
            return;
        }
        
        DLog(@"[In-App Purchases] Failed to load the list of products: %@", [error description]);
        
        for (NSDictionary *delegates in self.requestDelegates) {
            void (^failureBlock)(NSError *) = delegates[@"failure"];
            failureBlock(error);
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kInAppPurchasesNotificationProductsLoaded object:self userInfo:@{@"error": error}];
        
        [self.requestDelegates removeAllObjects];
        self.productsRequest = nil;
    });
}

#pragma mark - Purchase

- (void)buyProduct:(NSString *)productIdentifier success:(void (^)(void))successBlock failure:(void (^)(NSError *error))failureBlock {
    SKProduct *storeProduct = nil;
    
    for (SKProduct *product in self.products) {
        if ([product.productIdentifier isEqualToString:productIdentifier]) {
            storeProduct = product;
            break;
        }
    }
    
    if (!storeProduct) {
        if (failureBlock) {
            NSError *error = [NSError errorWithDomain:kInAppPurchasesErrorDomain code:kInAppPurchasesErrorNoSuchProductIdentifier userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Unknown product identifier", nil)}];
            failureBlock(error);
        }
        
        return;
    }
    
    if (successBlock || failureBlock) {
        NSMutableDictionary *delegates = [NSMutableDictionary dictionaryWithCapacity:2];
        
        if (successBlock)
            delegates[@"success"] = successBlock;
        
        if (successBlock)
            delegates[@"failure"] = failureBlock;
        
        self.transactionDelegates[productIdentifier] = delegates;
    }
    
    NSLog(@"[In-App Purchases] Buying %@ ...", productIdentifier);
    
    SKMutablePayment *payment = [SKMutablePayment paymentWithProduct:storeProduct];
    [[SKPaymentQueue defaultQueue] addPayment:payment];
}

#pragma mark SKPaymentTransactionObserver

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions {
    dispatch_async(dispatch_get_main_queue(), ^{
        for (SKPaymentTransaction *transaction in transactions) {
            switch (transaction.transactionState) {
                case SKPaymentTransactionStatePurchased:
                    [self completeTransaction:transaction];
                    break;
                case SKPaymentTransactionStateFailed:
                    [self failedTransaction:transaction];
                    break;
                default:
                    break;
            }
        }
    });
}

- (void)notifyOfSucceededTransaction:(SKPaymentTransaction *)transaction {
    NSDictionary *delegates = self.transactionDelegates[transaction.payment.productIdentifier];
    if (!delegates)
        return;
    
    [self.transactionDelegates removeObjectForKey:transaction.payment.productIdentifier];
    
    void (^successBlock)() = delegates[@"success"];
    if (successBlock)
        successBlock();
}

- (void)notifyOfFailedTransaction:(SKPaymentTransaction *)transaction error:(NSError *)error {
    NSDictionary *delegates = self.transactionDelegates[transaction.payment.productIdentifier];
    if (!delegates)
        return;
    
    [self.transactionDelegates removeObjectForKey:transaction.payment.productIdentifier];
    
    void (^failureBlock)(NSError *error) = delegates[@"failure"];
    if (failureBlock)
        failureBlock(error);
}

- (void)completeTransaction:(SKPaymentTransaction *)transaction {
    NSLog(@"[In-App Purchases] PAYMENT QUEUE: completeTransaction %@", transaction.transactionIdentifier);
    
    NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
    NSData *receipt = [NSData dataWithContentsOfURL:receiptURL];
    if (!receipt) {
        NSError *error = [NSError errorWithDomain:kInAppPurchasesErrorDomain code:kInAppPurchasesErrorReceiptNotFound userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Error reading transaction receipt", nil)}];
        [self notifyOfFailedTransaction:transaction error:error];
    }

    NSDictionary *params = @{@"purchase": @{@"transactionId": transaction.transactionIdentifier, @"receipt": [receipt base64EncodedStringWithOptions:0]}};
    
    [[RKObjectManager sharedManager] postObject:nil path:@"purchases" parameters:params success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"[In-App Purchases] PAYMENT QUEUE: completeTransaction - success");
            
            [self notifyOfSucceededTransaction:transaction];
            
            [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
            
            [[Analytics sharedInstance] trackSuccessfulTransaction:transaction];
            
            User *user = mappingResult.firstObject;
            [[DataProvider sharedInstance] updateCurrentUserFromUser:user];
        });
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSError *transactionError;
            NSInteger statusCode = operation.HTTPRequestOperation.response.statusCode;
            BOOL shouldFinishTransaction;
            if (statusCode >= 500 && statusCode < 600) {    // could be 500 (general server error), 503 (recoverable error - service unavailable)
                NSString *errorString = NSLocalizedString(@"Transaction cannot be verified on the server right now, but we will try to verify it again automatically on the next application launch", nil);
                transactionError = [NSError errorWithDomain:kInAppPurchasesErrorDomain
                                                       code:kInAppPurchasesErrorRecoverableServerError
                                                   userInfo:@{NSLocalizedDescriptionKey: errorString, NSUnderlyingErrorKey: error}];
                shouldFinishTransaction = NO;
            } else {                                        // 400, 402
                NSString *errorString = [NSString stringWithFormat:NSLocalizedString(@"Transaction cannot be verified on the server (%ld)", nil), (long)statusCode];
                transactionError = [NSError errorWithDomain:kInAppPurchasesErrorDomain
                                                       code:kInAppPurchasesErrorPermanentServerError
                                                   userInfo:@{NSLocalizedDescriptionKey: errorString, NSUnderlyingErrorKey: error}];
                shouldFinishTransaction = YES;
            }
            
            NSLog(@"[In-App Purchases] PAYMENT QUEUE: completeTransaction - failure, statusCode = %ld, finishing = %@, error = %@", (long)statusCode, (shouldFinishTransaction ? @"true" : @"false"), error.localizedDescription);
            
            [self notifyOfFailedTransaction:transaction error:transactionError];
            
            if (shouldFinishTransaction) {
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
            }
        });
    }];
}

- (void)failedTransaction:(SKPaymentTransaction *)transaction {
    NSLog(@"[In-App Purchases] PAYMENT QUEUE: failedTransaction %@, error: %@", transaction.transactionIdentifier, transaction.error.localizedDescription);
    
    NSError *error;
    
    if (transaction.error.code == SKErrorPaymentCancelled) {
        NSString *errorString = NSLocalizedString(@"Purchase cancelled", nil);
        error = [NSError errorWithDomain:kInAppPurchasesErrorDomain
                                    code:kInAppPurchasesErrorPurchaseCancelled
                                userInfo:@{NSLocalizedDescriptionKey: errorString, NSUnderlyingErrorKey: transaction.error}];
    } else {
        NSString *errorString = [NSString stringWithFormat:NSLocalizedString(@"Purchase failed: %@", nil), transaction.error.localizedDescription];
        error = [NSError errorWithDomain:kInAppPurchasesErrorDomain
                                    code:kInAppPurchasesErrorAppStoreError
                                userInfo:@{NSLocalizedDescriptionKey: errorString, NSUnderlyingErrorKey: transaction.error}];
    }
    [self notifyOfFailedTransaction:transaction error:error];
    
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}

@end
