//
//  MainViewController.h
//  wishbox
//
//  Copyright (c) 2015 Dmitry Mirkitanov. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "LoginViewController.h"

@interface MainViewController : UIViewController

- (void)switchToLoginControllerAnimated:(BOOL)animated;
- (void)switchToRootNavigationControllerAnimated:(BOOL)animated;
- (void)resetRootNavigationController;

@property (nonatomic, strong, readonly) LoginViewController *loginViewController;
@property (nonatomic, strong, readonly) UINavigationController *rootNavigationController;

@end
