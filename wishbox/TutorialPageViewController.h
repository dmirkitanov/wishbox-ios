//
//  TutorialPageViewController.h
//  wishbox
//
//  Copyright (c) 2015 Dmitry Mirkitanov. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol TutorialPageViewControllerDelegate;

@interface TutorialPageViewController : UIViewController

@property (nonatomic, weak) id<TutorialPageViewControllerDelegate> delegate;

@end

@protocol TutorialPageViewControllerDelegate <NSObject>

- (void)tutorialPageViewControllerOnNext:(TutorialPageViewController *)viewController;
- (void)tutorialPageViewControllerOnClose:(TutorialPageViewController *)viewController;

@end
