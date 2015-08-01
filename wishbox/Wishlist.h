//
//  Wishlist.h
//  wishbox
//
//  Copyright (c) 2015 Dmitry Mirkitanov. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Wishlist : NSObject <NSCoding>

// Don't forget to add new properties to initWithCoder / encodeWithCoder !

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSNumber *liked;
@property (nonatomic, copy) NSNumber *enabled;
@property (nonatomic, copy) NSNumber *likesCount;
@property (nonatomic, copy) NSArray *apps;
@property (nonatomic, copy) NSString *urlKey;
@property (nonatomic, copy) NSString *shareUrl;

@end
