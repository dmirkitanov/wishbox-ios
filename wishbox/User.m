//
//  User.m
//  wishbox
//
//  Copyright (c) 2015 Dmitry Mirkitanov. All rights reserved.
//

#import "User.h"

@implementation User

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:self.name forKey:@"name"];
    [encoder encodeObject:self.accountType forKey:@"accountType"];
    [encoder encodeObject:self.subscriptionExpiresAt forKey:@"subscriptionExpiresAt"];
    [encoder encodeObject:self.email forKey:@"email"];
    [encoder encodeObject:self.appStoreCountry forKey:@"appStoreCountry"];
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
    if ((self = [super init])) {
        self.name = [decoder decodeObjectForKey:@"name"];
        self.accountType = [decoder decodeObjectForKey:@"accountType"];
        self.subscriptionExpiresAt = [decoder decodeObjectForKey:@"subscriptionExpiresAt"];
        self.email = [decoder decodeObjectForKey:@"email"];
        self.appStoreCountry = [decoder decodeObjectForKey:@"appStoreCountry"];
    }
    return self;
}

@end
