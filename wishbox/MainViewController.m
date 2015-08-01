//
//  MainViewController.m
//  wishbox
//
//  Copyright (c) 2015 Dmitry Mirkitanov. All rights reserved.
//

#import "MainViewController.h"
#import "AppDelegate.h"

@interface MainViewController ()

@property (nonatomic, strong, readwrite) LoginViewController *loginViewController;
@property (nonatomic, strong, readwrite) UINavigationController *rootNavigationController;

@property (nonatomic) UIStatusBarStyle statusBarStyle;

@end

@implementation MainViewController

- (UIStatusBarStyle)preferredStatusBarStyle{
    return self.statusBarStyle;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    UIStoryboard *storyboard = [AppDelegate instance].window.rootViewController.storyboard;

    if ([[AppDelegate instance] isLoggedIn]) {
        self.rootNavigationController = [storyboard instantiateViewControllerWithIdentifier:@"RootNavigationController"];
        [self addChildViewController:self.rootNavigationController];
        [self.view addSubview:self.rootNavigationController.view];
        [self.rootNavigationController didMoveToParentViewController:self];
    } else {
        self.loginViewController = [storyboard instantiateViewControllerWithIdentifier:@"LoginViewController"];
        [self addChildViewController:self.loginViewController];
        [self.view addSubview:self.loginViewController.view];
        [self.loginViewController didMoveToParentViewController:self];
    }

    [self updateStatusBarStyle];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)updateStatusBarStyle {
    self.statusBarStyle = (self.rootNavigationController ? UIStatusBarStyleLightContent : UIStatusBarStyleDefault);
    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)switchToLoginControllerAnimated:(BOOL)animated {
    if (!self.rootNavigationController || self.loginViewController)
        return;

    self.loginViewController = [[AppDelegate instance].window.rootViewController.storyboard instantiateViewControllerWithIdentifier:@"LoginViewController"];

    [self switchFromViewController:self.rootNavigationController toViewController:self.loginViewController animated:animated completion:^{
        self.rootNavigationController = nil;
        [self updateStatusBarStyle];
    }];
}

- (void)resetRootNavigationController {
    if (!self.rootNavigationController)
        return;
    
    void (^resetBlock)() = ^{
        [self.rootNavigationController willMoveToParentViewController:nil];
        [self.rootNavigationController.view removeFromSuperview];
        [self.rootNavigationController removeFromParentViewController];
        
        self.rootNavigationController = [[AppDelegate instance].window.rootViewController.storyboard instantiateViewControllerWithIdentifier:@"RootNavigationController"];
        [self addChildViewController:self.rootNavigationController];
        [self.view addSubview:self.rootNavigationController.view];
        [self.rootNavigationController didMoveToParentViewController:self];
    };
    
    if (self.rootNavigationController.presentedViewController) {
        [self.rootNavigationController dismissViewControllerAnimated:NO completion:^{
            resetBlock();
        }];
    } else {
        resetBlock();
    }
}

- (void)switchToRootNavigationControllerAnimated:(BOOL)animated {
    if (!self.loginViewController || self.rootNavigationController)
        return;
    
    self.rootNavigationController = [[AppDelegate instance].window.rootViewController.storyboard instantiateViewControllerWithIdentifier:@"RootNavigationController"];
    
    [self switchFromViewController:self.loginViewController toViewController:self.rootNavigationController animated:animated completion:^{
        self.loginViewController = nil;
        [self updateStatusBarStyle];
    }];
}

- (void)switchFromViewController:(UIViewController *)oldViewController toViewController:(UIViewController *)newViewController animated:(BOOL)animated completion:(void (^)(void))completion {
    if (oldViewController == newViewController)
        return;
    
    void (^switchBlock)() = ^{
        [oldViewController willMoveToParentViewController:nil];
        [self addChildViewController:newViewController];
        
        newViewController.view.frame = self.view.bounds;
        newViewController.view.alpha = 0;
        [self.view addSubview:newViewController.view];
        
        NSTimeInterval duration = (animated ? .5 : 0);
        void (^animations)() = (animated ? ^{
            oldViewController.view.alpha = 0;
            newViewController.view.alpha = 1;
        } : nil);
        
        [UIView animateWithDuration:duration delay:0 options:0 animations:animations completion:^(BOOL finished) {
            [oldViewController.view removeFromSuperview];
            [oldViewController removeFromParentViewController];
            [newViewController didMoveToParentViewController:self];
            
            if (completion)
                completion();
        }];
    };
    
    if (oldViewController.presentedViewController) {
        [oldViewController dismissViewControllerAnimated:animated completion:^{
            switchBlock();
        }];
    } else {
        switchBlock();
    }
}

@end
