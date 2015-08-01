//
//  Tutorial2ViewController.m
//  wishbox
//
//  Copyright (c) 2015 Dmitry Mirkitanov. All rights reserved.
//

#import "Tutorial2ViewController.h"

@interface Tutorial2ViewController ()

@property (weak, nonatomic) IBOutlet UIButton *tryNowButton;
@property (weak, nonatomic) IBOutlet UIButton *tryLaterButton;

@end

@implementation Tutorial2ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.tryNowButton.layer.cornerRadius = 5;
}

- (IBAction)tryNow:(id)sender {
    [self.delegate tutorialPageViewControllerOnClose:self];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"itms-apps://"]];
}

- (IBAction)tryLater:(id)sender {
    [self.delegate tutorialPageViewControllerOnClose:self];
}

@end
