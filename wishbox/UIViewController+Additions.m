//
//  UIViewController+Additions.m
//  wishbox
//
//  Copyright (c) 2015 Dmitry Mirkitanov. All rights reserved.
//

#import "UIViewController+Additions.h"

@implementation UIViewController (Additions)

- (id<UILayoutSupport>)ms_navigationBarTopLayoutGuide {
    if (self.parentViewController && ![self.parentViewController isKindOfClass:UINavigationController.class]) {
        return self.parentViewController.ms_navigationBarTopLayoutGuide;
    } else {
        return self.topLayoutGuide;
    }
}

- (id<UILayoutSupport>)ms_navigationBarBottomLayoutGuide {
    if (self.parentViewController && ![self.parentViewController isKindOfClass:UINavigationController.class]) {
        return self.parentViewController.ms_navigationBarBottomLayoutGuide;
    } else {
        return self.bottomLayoutGuide;
    }
}

@end
