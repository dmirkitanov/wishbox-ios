//
//  SubscribeViewController.m
//  wishbox
//
//  Copyright (c) 2015 Dmitry Mirkitanov. All rights reserved.
//

#import "SubscribeViewController.h"
#import "AppDelegate.h"
#import "InAppPurchases.h"
#import "Analytics.h"

static NSString *const kSubscribeNotificationsProductId = @"notifications.12m";

@interface SubscribeViewController ()

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicatorView;
@property (weak, nonatomic) IBOutlet UIButton *buyButton;

@property (weak, nonatomic) IBOutlet UIImageView *notificationExampleImageView;

@end

@implementation SubscribeViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    CAGradientLayer *gradient1 = [CAGradientLayer layer];
    gradient1.frame = CGRectMake(0, 0, self.notificationExampleImageView.bounds.size.width, 3);
    gradient1.colors = [NSArray arrayWithObjects:(id)[UIColorFromRGBWithAlpha(0xF6F6F6, 1) CGColor], (id)[UIColorFromRGBWithAlpha(0xF6F6F6, 0) CGColor], nil];
    [self.notificationExampleImageView.layer insertSublayer:gradient1 atIndex:0];

    CAGradientLayer *gradient2 = [CAGradientLayer layer];
    gradient2.frame = CGRectMake(0, self.notificationExampleImageView.bounds.size.height - 3, self.notificationExampleImageView.bounds.size.width, 3);
    gradient2.colors = [NSArray arrayWithObjects:(id)[UIColorFromRGBWithAlpha(0xF6F6F6, 0) CGColor], (id)[UIColorFromRGBWithAlpha(0xF6F6F6, 1) CGColor], nil];
    [self.notificationExampleImageView.layer insertSublayer:gradient2 atIndex:0];
    
    self.buyButton.titleLabel.adjustsFontSizeToFitWidth = YES;
}

- (void)viewWillAppear:(BOOL)animated {
    NSString *productPrice = [[InAppPurchases sharedInstance] localizedPriceForProductIdentifier:kSubscribeNotificationsProductId];
    
    [self updateBuyButtonWithPrice:productPrice forceVisible:NO animated:NO];
 
    if (!productPrice) {
        [[InAppPurchases sharedInstance] requestProductsWithSuccess:^{
            NSString *loadedProductPrice = [[InAppPurchases sharedInstance] localizedPriceForProductIdentifier:kSubscribeNotificationsProductId];
            [self updateBuyButtonWithPrice:loadedProductPrice forceVisible:YES animated:YES];
        } failure:^(NSError *error) {
            [self updateBuyButtonWithPrice:nil forceVisible:YES animated:YES];
        }];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [[Analytics sharedInstance] trackScreen:@"Subscribe"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)updateBuyButtonWithPrice:(NSString *)price forceVisible:(BOOL)forceVisible animated:(BOOL)animated {
    if (!price) {
        [self.buyButton setTitleColor:[UIColor colorWithWhite:1 alpha:0.6] forState:UIControlStateNormal];
        [self.buyButton setTitle:NSLocalizedString(@" AppStore is not available, please try again ", nil) forState:UIControlStateNormal];
    } else {
        [self.buyButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
#ifdef APPSTORE_SCREENSHOTS
        NSString *buyButtonTitle = @"Subscribe";
#else
        NSString *buyButtonTitle = [NSString stringWithFormat:NSLocalizedString(@"Subscribe for %@ / year", nil), price];
#endif
        [self.buyButton setTitle:buyButtonTitle forState:UIControlStateNormal];
    }

    BOOL buyButtonHidden = (forceVisible ? NO : (price == nil));
    
    [UIView animateWithDuration:(animated ? 0.3 : 0) animations:^{
        self.activityIndicatorView.alpha = (buyButtonHidden ? 1 : 0);
        self.buyButton.hidden = (buyButtonHidden ? 0 : 1);
    } completion:^(BOOL finished) {
        self.activityIndicatorView.hidden = !buyButtonHidden;
        self.buyButton.hidden = buyButtonHidden;
    }];
}

- (IBAction)cancel:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)subscribe:(id)sender {
    [[Analytics sharedInstance] trackEventWithCategory:@"UI" action:@"SubscribeVC_Event" label:@"subscribe" value:nil];
    
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeGradient];
    
    [[InAppPurchases sharedInstance] buyProduct:kSubscribeNotificationsProductId success:^{
        [SVProgressHUD dismiss];

        [self dismissViewControllerAnimated:YES completion:^{
            [self.delegate subscribeViewControllerDidSubscribe:self];
        }];
    } failure:^(NSError *error) {
        [SVProgressHUD dismiss];

        if ([error.domain isEqualToString:kInAppPurchasesErrorDomain] && error.code == kInAppPurchasesErrorPurchaseCancelled)
            return;
        
        [self showAlertForError:error];
    }];
}

- (void)showAlertForError:(NSError *)error {
    NSString *title;
    if ([error.domain isEqualToString:kInAppPurchasesErrorDomain] && error.code == kInAppPurchasesErrorRecoverableServerError) {
        title = NSLocalizedString(@"Purchase", nil);
    } else {
        title = NSLocalizedString(@"Error", nil);
    }
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
