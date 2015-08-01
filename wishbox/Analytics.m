//
//  Analytics.m
//  wishbox
//
//  Copyright (c) 2015 Dmitry Mirkitanov. All rights reserved.
//

#import "Analytics.h"
#import <StoreKit/StoreKit.h>
#import "InAppPurchases.h"

@interface Analytics ()

@property (nonatomic, strong, readonly) NSString *deferredTransactionsFile;

@end

@implementation Analytics

@synthesize deferredTransactionsFile = _deferredTransactionsFile;

+ (instancetype)sharedInstance {
    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    
    return sharedInstance;
}

- (instancetype)init {
    if ((self = [super init])) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processDeferredTransactions:) name:kInAppPurchasesNotificationProductsLoaded object:nil];
    }
    return self;
}

- (void)initializeAnalytics {
//    [GAI sharedInstance].logger.logLevel = kGAILogLevelVerbose;
    [GAI sharedInstance].dispatchInterval = 20;

#ifdef PRODUCTION_ENV
    [[GAI sharedInstance] trackerWithTrackingId:@"UA-60491174-3"];
#else
    [[GAI sharedInstance] trackerWithTrackingId:@"UA-60491174-2"];
#endif
}

- (NSString *)deferredTransactionsFile {
    if (_deferredTransactionsFile)
        return _deferredTransactionsFile;
    
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    
    _deferredTransactionsFile = [documentsPath stringByAppendingPathComponent:@"analyticsDeferredTransactions.plist"];
    
    return _deferredTransactionsFile;
}

- (void)processDeferredTransactions:(NSNotification *)notification {
    @synchronized (self.deferredTransactionsFile) {
        NSArray *deferredTransactions = [NSKeyedUnarchiver unarchiveObjectWithFile:self.deferredTransactionsFile];
        if (isEmpty(deferredTransactions) || ![deferredTransactions isKindOfClass:[NSArray class]])
            return;
        
        NSMutableArray *unprocessedTransactions = [NSMutableArray array];
        
        for (NSDictionary *transactionDict in deferredTransactions) {
            if (![self sendTransaction:transactionDict]) {
                [unprocessedTransactions addObject:transactionDict];
                continue;
            }
        }

        if ([unprocessedTransactions count] == 0) {
            [[NSFileManager defaultManager] removeItemAtPath:self.deferredTransactionsFile error:nil];
        } else {
            [NSKeyedArchiver archiveRootObject:unprocessedTransactions toFile:self.deferredTransactionsFile];
        }
    }
}

- (CGFloat)estimateRevenuePercentForPriceLocale:(NSLocale *)locale {
    const CGFloat defaultPercent = 0.7;
    
    NSString *countryCode = [locale objectForKey:NSLocaleCountryCode];
    NSString *currencyCode = [locale objectForKey:NSLocaleCurrencyCode];

    NSDictionary *estimates = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"AnalyticsEstimatedRevenue" ofType:@"plist"]];
    if (!estimates)
        return defaultPercent;
    
    NSDictionary *currencyEstimates = estimates[currencyCode];
    if (!currencyEstimates)
        return defaultPercent;
    
    NSNumber *countryEstimate = currencyEstimates[countryCode];
    if (countryEstimate)
        return [countryEstimate floatValue];
    
    countryEstimate = currencyEstimates[@"*"];
    if (countryEstimate)
        return [countryEstimate floatValue];

    return defaultPercent;
}

- (BOOL)sendTransaction:(NSDictionary *)transactionDict {
    SKProduct *product = [[InAppPurchases sharedInstance] productForProductIdentifier:transactionDict[@"productId"]]; 
    if (!product)
        return NO;
    
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    CGFloat estimatedRevenuePercent = [self estimateRevenuePercentForPriceLocale:product.priceLocale];
    NSNumber *revenue = @(product.price.floatValue * [transactionDict[@"quantity"] integerValue] * estimatedRevenuePercent);
    [tracker send:[[GAIDictionaryBuilder createTransactionWithId:transactionDict[@"transactionId"]
                                                     affiliation:@"App Store"
                                                         revenue:revenue
                                                             tax:@0
                                                        shipping:@0
                                                    currencyCode:[product.priceLocale objectForKey:NSLocaleCurrencyCode]] build]];
    
    [tracker send:[[GAIDictionaryBuilder createItemWithTransactionId:transactionDict[@"transactionId"]
                                                                name:product.localizedTitle
                                                                 sku:transactionDict[@"productId"]
                                                            category:@"In-App Purchase"
                                                               price:product.price
                                                            quantity:transactionDict[@"quantity"]
                                                        currencyCode:[product.priceLocale objectForKey:NSLocaleCurrencyCode]] build]];

    return YES;
}

- (void)trackSuccessfulTransaction:(SKPaymentTransaction *)transaction {
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];

    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"Purchase"
                                                          action:@"success"
                                                           label:transaction.payment.productIdentifier
                                                           value:nil] build]];
    
    NSDictionary *transactionDict = @{@"productId": transaction.payment.productIdentifier,
                                      @"quantity": @(transaction.payment.quantity),
                                      @"transactionId": transaction.transactionIdentifier};
    
    BOOL sent = [self sendTransaction:transactionDict];
    if (!sent) {
        @synchronized (self.deferredTransactionsFile) {
            NSArray *deferredTransactions = [NSKeyedUnarchiver unarchiveObjectWithFile:self.deferredTransactionsFile];
            if (isEmpty(deferredTransactions) || ![deferredTransactions isKindOfClass:[NSArray class]]) {
                deferredTransactions = [NSArray array];
            }
            
            NSMutableArray *unprocessedTransactions = [NSMutableArray arrayWithArray:deferredTransactions];
            [unprocessedTransactions addObject:transactionDict];
            
            [NSKeyedArchiver archiveRootObject:unprocessedTransactions toFile:self.deferredTransactionsFile];
        }
    }
}

- (void)trackEventWithCategory:(NSString *)category action:(NSString *)action label:(NSString *)label value:(NSNumber *)value {
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:category
                                                          action:action
                                                           label:label
                                                           value:value] build]];
}

- (void)trackScreen:(NSString *)name {
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    
    [tracker set:kGAIScreenName value:name];
    [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
}

@end
