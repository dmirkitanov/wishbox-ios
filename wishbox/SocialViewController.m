//
//  SocialViewController.m
//  wishbox
//
//  Copyright (c) 2015 Dmitry Mirkitanov. All rights reserved.
//

#import "SocialViewController.h"
#import "Wishlist.h"
#import "FriendsTableViewController.h"
#import "FriendAppsViewController.h"

@interface SocialViewController ()

@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;

@property (nonatomic, strong) UIViewController *shareViewController;
@property (nonatomic, strong) UIViewController *friendsViewController;

@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (nonatomic, copy) NSArray *allViewControllers;
@property (nonatomic, strong) UIViewController *currentViewController;

@end

@implementation SocialViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.shareViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"share"];
    self.friendsViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"friends"];
    
    self.allViewControllers = [[NSArray alloc] initWithObjects:self.shareViewController, self.friendsViewController, nil];
    
    self.segmentedControl.selectedSegmentIndex = 0;
    [self cycleFromViewController:self.currentViewController toViewController:[self.allViewControllers objectAtIndex:self.segmentedControl.selectedSegmentIndex] complete:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (self.urlKeyTrigger) {
        void (^completeBlock)() = ^{
            FriendAppsViewController *friendAppsViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"friendApps"];
            friendAppsViewController.urlKey = self.urlKeyTrigger;
            [self.navigationController pushViewController:friendAppsViewController animated:NO];
            
            self.urlKeyTrigger = nil;
        };
        
        if (self.segmentedControl.selectedSegmentIndex != 1) {
            self.segmentedControl.selectedSegmentIndex = 1;
            
            UIViewController *incomingViewController = [self.allViewControllers objectAtIndex:1];
            [self cycleFromViewController:self.currentViewController toViewController:incomingViewController complete:completeBlock];
        } else {
            completeBlock();
        }
    }
}

- (void)cycleFromViewController:(UIViewController*)oldVC toViewController:(UIViewController*)newVC complete:(void (^)())completeBlock {
    if (newVC == oldVC || !newVC) {
        if (completeBlock)
            completeBlock();
        return;
    }
    
    if (!oldVC) {
        [self addChildViewController:newVC];
        [self.containerView addSubview:newVC.view];
        [newVC didMoveToParentViewController:self];
        self.currentViewController = newVC;

        newVC.view.frame = self.containerView.bounds;
        
        if (completeBlock)
            completeBlock();

        return;
    }
    
    [oldVC willMoveToParentViewController:nil];
    [self addChildViewController:newVC];
    
    [self.containerView addSubview:newVC.view];
    [oldVC.view removeFromSuperview];
    
    newVC.view.frame = self.containerView.bounds;
    
    [oldVC removeFromParentViewController];
    [newVC didMoveToParentViewController:self];
    self.currentViewController = newVC;
    
    if (completeBlock)
        completeBlock();
}

- (IBAction)segmentedControlDidChangeValue:(UISegmentedControl *)sender {
    NSUInteger index = sender.selectedSegmentIndex;
    
    if (UISegmentedControlNoSegment != index) {
        UIViewController *incomingViewController = [self.allViewControllers objectAtIndex:index];
        [self cycleFromViewController:self.currentViewController toViewController:incomingViewController complete:nil];
    }
}

- (IBAction)done:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
