//
//  App.m
//  wishbox
//
//  Copyright (c) 2015 Dmitry Mirkitanov. All rights reserved.
//

#import "App.h"

@implementation App

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:self.appId forKey:@"appId"];
    [encoder encodeObject:self.appStoreId forKey:@"appStoreId"];
    [encoder encodeObject:self.name forKey:@"name"];
    [encoder encodeObject:self.category forKey:@"category"];
    [encoder encodeObject:self.iconUrl forKey:@"iconUrl"];
    [encoder encodeObject:self.price forKey:@"price"];
    [encoder encodeObject:self.formattedPrice forKey:@"formattedPrice"];
    [encoder encodeObject:self.prevPrice forKey:@"prevPrice"];
    [encoder encodeObject:self.prevFormattedPrice forKey:@"prevFormattedPrice"];
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
    if ((self = [super init])) {
        self.appId = [decoder decodeObjectForKey:@"appId"];
        self.appStoreId = [decoder decodeObjectForKey:@"appStoreId"];
        self.name = [decoder decodeObjectForKey:@"name"];
        self.category = [decoder decodeObjectForKey:@"category"];
        self.iconUrl = [decoder decodeObjectForKey:@"iconUrl"];
        self.price = [decoder decodeObjectForKey:@"price"];
        self.formattedPrice = [decoder decodeObjectForKey:@"formattedPrice"];
        self.prevPrice = [decoder decodeObjectForKey:@"prevPrice"];
        self.prevFormattedPrice = [decoder decodeObjectForKey:@"prevFormattedPrice"];
    }
    return self;
}

@end
