//
//  TutorialViewController.m
//  wishbox
//
//  Copyright (c) 2015 Dmitry Mirkitanov. All rights reserved.
//

#import "TutorialViewController.h"
#import "TutorialPageViewController.h"

@interface TutorialViewController () <UIPageViewControllerDataSource, TutorialPageViewControllerDelegate>

@property (nonatomic, strong) NSArray *pages;
@property (nonatomic) NSInteger presentationIndex;

@end

@implementation TutorialViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.dataSource = self;
    self.presentationIndex = 0;
    
    TutorialPageViewController *viewController1 = [self.storyboard instantiateViewControllerWithIdentifier:@"tutorial1"];
    viewController1.delegate = self;

    TutorialPageViewController *viewController2 = [self.storyboard instantiateViewControllerWithIdentifier:@"tutorial2"];
    viewController2.delegate = self;

    self.pages = @[viewController1, viewController2];

    [self setViewControllers:@[self.pages[0]] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];

    UIPageControl *pageControl = [UIPageControl appearanceWhenContainedIn:[self class], nil];
    pageControl.pageIndicatorTintColor = [UIColor lightGrayColor];
    pageControl.currentPageIndicatorTintColor = [UIColor blackColor];
    pageControl.backgroundColor = [UIColor clearColor];

    self.view.backgroundColor = UIColorFromRGB(0xF6F6F6);
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
    NSUInteger currentIndex = [self.pages indexOfObject:viewController];
    
    if (currentIndex > 0) {
        return self.pages[currentIndex - 1];
    }

    return nil;
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
    NSUInteger currentIndex = [self.pages indexOfObject:viewController];
    
    if (currentIndex < ([self.pages count] - 1)) {
        return self.pages[currentIndex + 1];
    }
    
    return nil;
}

- (NSInteger)presentationCountForPageViewController:(UIPageViewController *)pageViewController {
    return [self.pages count];
}

- (NSInteger)presentationIndexForPageViewController:(UIPageViewController *)pageViewController {
    return self.presentationIndex;
}

- (void)tutorialPageViewControllerOnNext:(TutorialPageViewController *)viewController {
    NSUInteger currentIndex = [self.pages indexOfObject:viewController];
    
    if (currentIndex < ([self.pages count] - 1)) {
        self.presentationIndex = currentIndex + 1;
        [self setViewControllers:@[self.pages[currentIndex + 1]] direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:nil];
    }
}

- (void)tutorialPageViewControllerOnClose:(TutorialPageViewController *)viewController {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
