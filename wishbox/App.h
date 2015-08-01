//
//  App.h
//  wishbox
//
//  Copyright (c) 2015 Dmitry Mirkitanov. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface App : NSObject <NSCoding>

// Don't forget to add new properties to initWithCoder / encodeWithCoder !

@property (nonatomic, copy) NSString *appId;
@property (nonatomic, copy) NSString *appStoreId;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *category;
@property (nonatomic, copy) NSString *iconUrl;
@property (nonatomic, copy) NSNumber *price;
@property (nonatomic, copy) NSString *formattedPrice;
@property (nonatomic, copy) NSNumber *prevPrice;
@property (nonatomic, copy) NSString *prevFormattedPrice;

@end
