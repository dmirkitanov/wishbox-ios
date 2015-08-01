//
//  Tutorial1ViewController.m
//  wishbox
//
//  Copyright (c) 2015 Dmitry Mirkitanov. All rights reserved.
//

#import "Tutorial1ViewController.h"

@interface Tutorial1ViewController ()

@end

@implementation Tutorial1ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (IBAction)next:(id)sender {
    [self.delegate tutorialPageViewControllerOnNext:self];
}

@end
