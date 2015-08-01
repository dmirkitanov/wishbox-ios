//
//  Wishlist.m
//  wishbox
//
//  Copyright (c) 2015 Dmitry Mirkitanov. All rights reserved.
//

#import "Wishlist.h"

@implementation Wishlist

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:self.name forKey:@"name"];
    [encoder encodeObject:self.liked forKey:@"liked"];
    [encoder encodeObject:self.enabled forKey:@"enabled"];
    [encoder encodeObject:self.likesCount forKey:@"likesCount"];
    [encoder encodeObject:self.apps forKey:@"apps"];
    [encoder encodeObject:self.urlKey forKey:@"urlKey"];
    [encoder encodeObject:self.shareUrl forKey:@"shareUrl"];
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
    if ((self = [super init])) {
        self.name = [decoder decodeObjectForKey:@"name"];
        self.liked = [decoder decodeObjectForKey:@"liked"];
        self.enabled = [decoder decodeObjectForKey:@"enabled"];
        self.likesCount = [decoder decodeObjectForKey:@"likesCount"];
        self.apps = [decoder decodeObjectForKey:@"apps"];
        self.urlKey = [decoder decodeObjectForKey:@"urlKey"];
        self.shareUrl = [decoder decodeObjectForKey:@"shareUrl"];
    }
    return self;
}

@end
