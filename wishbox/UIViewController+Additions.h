//
//  UIViewController+Additions.h
//  wishbox
//
//  Copyright (c) 2015 Dmitry Mirkitanov. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIViewController (Additions)

- (id<UILayoutSupport>)ms_navigationBarTopLayoutGuide;
- (id<UILayoutSupport>)ms_navigationBarBottomLayoutGuide;

@end
