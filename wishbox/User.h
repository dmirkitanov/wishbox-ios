//
//  User.h
//  wishbox
//
//  Copyright (c) 2015 Dmitry Mirkitanov. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface User : NSObject

// Don't forget to add new properties to initWithCoder / encodeWithCoder !

@property (nonatomic, copy) NSString *login;
@property (nonatomic, copy) NSString *apiToken;

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *accountType;
@property (nonatomic, copy) NSDate *subscriptionExpiresAt;
@property (nonatomic, copy) NSString *email;
@property (nonatomic, copy) NSString *appStoreCountry;

@end
