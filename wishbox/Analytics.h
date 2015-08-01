//
//  Analytics.h
//  wishbox
//
//  Copyright (c) 2015 Dmitry Mirkitanov. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SKPaymentTransaction;

@interface Analytics : NSObject

+ (instancetype)sharedInstance;

- (void)initializeAnalytics;

- (void)trackSuccessfulTransaction:(SKPaymentTransaction *)transaction;
- (void)trackEventWithCategory:(NSString *)category action:(NSString *)action label:(NSString *)label value:(NSNumber *)value;
- (void)trackScreen:(NSString *)name;

@end
