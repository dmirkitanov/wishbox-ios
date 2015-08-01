//
//  SubscribeViewController.h
//  wishbox
//
//  Copyright (c) 2015 Dmitry Mirkitanov. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SubscribeViewControllerDelegate;

@interface SubscribeViewController : UIViewController

@property (nonatomic, weak) id<SubscribeViewControllerDelegate> delegate;

@end

@protocol SubscribeViewControllerDelegate <NSObject>

@required
- (void)subscribeViewControllerDidSubscribe:(SubscribeViewController *)viewController;

@end
