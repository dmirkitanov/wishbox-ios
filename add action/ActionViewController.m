//
//  ActionViewController.m
//  add action
//
//  Copyright (c) 2015 Dmitry Mirkitanov. All rights reserved.
//

#import "ActionViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <QuartzCore/QuartzCore.h>
#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>

#import "NewAppsService.h"
#import "Settings.h"
#import "Utils.h"
#import <AFNetworking/AFNetworking.h>

typedef NS_ENUM(NSInteger, ActionState) {
    kActionStateActivityIndicator = 0,
    kActionStateInvalidLink = 1,
    kActionStateNotLoggedIn = 2,
    kActionStateNetworkError = 3,
    kActionStateAddButtonActive = 4
};

@interface ActionViewController ()

@property (weak, nonatomic) IBOutlet UIView *appContainerView;
@property (weak, nonatomic) IBOutlet UIView *actionContainerView;

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UITextField *appDescriptionTextField;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicatorView;
@property (weak, nonatomic) IBOutlet UILabel *errorLabel;
@property (weak, nonatomic) IBOutlet UIButton *addButton;

@property (nonatomic, strong) NSDictionary *appStoreData;
@property (nonatomic) BOOL appDetailsAvailable;

@end

@implementation ActionViewController

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
    }

    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.appStoreData = nil;
    self.appDetailsAvailable = NO;
    
    [[NewAppsService sharedInstance] createUrlSession];
    
    CGFloat scale = [[UIScreen mainScreen] scale];
    CGFloat borderWidth = scale > 0.0 ? 1.0 / scale : 1.0;
    
    self.appContainerView.layer.borderWidth = borderWidth;
    self.appContainerView.layer.borderColor = [UIColor lightGrayColor].CGColor;

    self.actionContainerView.layer.borderWidth = borderWidth;
    self.actionContainerView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    
    self.addButton.layer.borderWidth = borderWidth;
    self.addButton.layer.borderColor = [UIColor lightGrayColor].CGColor;
    
    self.imageView.layer.borderWidth = borderWidth;
    self.imageView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.imageView.layer.cornerRadius = 17.5;
    self.imageView.layer.masksToBounds = YES;
    
    for (NSExtensionItem *item in self.extensionContext.inputItems) {
        NSItemProvider *textProvider = nil;
        NSItemProvider *imageProvider = nil;
        NSItemProvider *urlProvider = nil;
        
        for (NSItemProvider *itemProvider in item.attachments) {
            NSLog(@"item: %@", [itemProvider description]);
            
            if ([itemProvider hasItemConformingToTypeIdentifier:(NSString *)kUTTypePlainText]) {
                textProvider = itemProvider;

            }

            if ([itemProvider hasItemConformingToTypeIdentifier:(NSString *)kUTTypeImage]) {
                imageProvider = itemProvider;
                
            }
            
            if ([itemProvider hasItemConformingToTypeIdentifier:(NSString *)kUTTypeURL]) {
                urlProvider = itemProvider;
            }
        }
        
        if (urlProvider) {
            NSLog(@"found url provider");

            if (textProvider) {
                NSLog(@"found text provider");

                [textProvider loadItemForTypeIdentifier:(NSString *)kUTTypePlainText options:nil completionHandler:^(id data, NSError *error) {
                    if (!data)
                        return;

                    dispatch_async(dispatch_get_main_queue(), ^{
                        self.appDescriptionTextField.text = data;
                    });
                }];
            }
            
            if (imageProvider) {
                NSLog(@"found image provider");

                [imageProvider loadItemForTypeIdentifier:(NSString *)kUTTypeImage options:nil completionHandler:^(id data, NSError *error) {
                    if (!data)
                        return;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self.imageView.image = data;
                    });
                }];
            }
            
            [urlProvider loadItemForTypeIdentifier:(NSString *)kUTTypeURL options:nil completionHandler:^(NSURL *url, NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (!url) {
                        [self updateActionState:kActionStateInvalidLink];
                        return;
                    }
                    
                    // check if user is logged in
                    NSUserDefaults *sharedUserDefaults = [[NSUserDefaults alloc] initWithSuiteName:kSharedGroupName];
                    BOOL loggedIn = [sharedUserDefaults boolForKey:kSharedDefaultsKeyLoggedIn];
                    if (!loggedIn) {
                        [self updateActionState:kActionStateNotLoggedIn];
                        return;
                    }

                    
                    self.appDetailsAvailable = (imageProvider && textProvider);
                    
                    NSDictionary *appStoreData = [self extractAppStoreDataFromUrl:url];
                    if (appStoreData && self.appDetailsAvailable) {
                        // we have all the pieces
                        [self updateActionState:kActionStateAddButtonActive];
                        self.appStoreData = appStoreData;
                        return;
                    }
                    
                    if (appStoreData) {
                        // we have just correct url, try to load image&text from the app store
                        self.appStoreData = appStoreData;
                        // [self downloadAppInfo];
                        self.appDescriptionTextField.text = url.absoluteString;
                        [self updateActionState:kActionStateAddButtonActive];
                        return;
                    }
                    
                    // no appstore data yet, try to resolve redirects
                    [self resolveRedirectsForUrl:url];
                });
            }];

            
            break;
        }
    }
}

- (void)resolveRedirectsForUrl:(NSURL *)url {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"HEAD"];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"success: %@", [operation.response.URL absoluteString]);
            
            NSDictionary *appStoreData = [self extractAppStoreDataFromUrl:operation.response.URL];
            if (!appStoreData) {
                [self updateActionState:kActionStateInvalidLink];
                return;
            }
            
            if (!self.appDetailsAvailable) {
                // we have just correct url, try to load image&text from the app store
                self.appStoreData = appStoreData;
                // TODO: implement this
                // [self downloadAppInfo];
                self.appDescriptionTextField.text = url.absoluteString;
                [self updateActionState:kActionStateAddButtonActive];
                return;
            }

            // we have all the pieces
            [self updateActionState:kActionStateAddButtonActive];
            self.appStoreData = appStoreData;
        });
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"failure: %@", error);
            [self updateActionState:kActionStateNetworkError];
        });
    }];
    [operation start];
}

- (void)updateActionState:(ActionState)actionState {
    switch (actionState) {
        case kActionStateActivityIndicator: {
            self.errorLabel.hidden = YES;
            self.addButton.hidden = YES;
            self.activityIndicatorView.hidden = NO;
        } break;
            
        case kActionStateInvalidLink: {
            self.errorLabel.hidden = NO;
            self.addButton.hidden = YES;
            self.activityIndicatorView.hidden = YES;
            self.errorLabel.text = @"Not an AppStore link";
            self.errorLabel.textColor = [UIColor grayColor];
        } break;
            
        case kActionStateNotLoggedIn: {
            self.errorLabel.hidden = NO;
            self.addButton.hidden = YES;
            self.activityIndicatorView.hidden = YES;
            self.errorLabel.text = @"You're not logged in - please login in the main app";
            self.errorLabel.textColor = [UIColor redColor];
        } break;
            
        case kActionStateNetworkError: {
            self.errorLabel.hidden = NO;
            self.addButton.hidden = YES;
            self.activityIndicatorView.hidden = YES;
            self.errorLabel.text = @"Connection error, please try again";
            self.errorLabel.textColor = [UIColor grayColor];
        } break;
            
        case kActionStateAddButtonActive: {
            self.errorLabel.hidden = YES;
            self.addButton.hidden = NO;
            self.activityIndicatorView.hidden = YES;
        } break;
            
        default:
            break;
    }
}

- (NSDictionary *)extractAppStoreDataFromUrl:(NSURL *)url {
    NSLog(@"url: %@", [url absoluteString]);
    
    if (![url.host isEqualToString:@"itunes.apple.com"])
        return nil;
    
    NSString *unparsedId = url.lastPathComponent;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^id(\\d+)$" options:0 error:nil];
    NSTextCheckingResult *match = [regex firstMatchInString:unparsedId options:0 range:NSMakeRange(0, [unparsedId length])];
    if (!match)
        return nil;
    
    NSMutableDictionary *appStoreData = [NSMutableDictionary dictionary];

    appStoreData[@"appStoreId"] = [unparsedId substringWithRange:[match rangeAtIndex:1]];
    
    if ([url.pathComponents count] >= 2 && [url.pathComponents[1] length] == 2) {
        appStoreData[@"country"] = url.pathComponents[1];
    }
    
    NSLog(@"appStoreData: %@", appStoreData);
    
    return [NSDictionary dictionaryWithDictionary:appStoreData];
}

- (IBAction)cancel:(id)sender {
    [self.extensionContext completeRequestReturningItems:self.extensionContext.inputItems completionHandler:nil];
}

- (IBAction)addToWishlist:(id)sender {
    [[NewAppsService sharedInstance] startNewAppRequest:self.appStoreData[@"appStoreId"] country:self.appStoreData[@"country"]];
    
    [self.extensionContext completeRequestReturningItems:self.extensionContext.inputItems completionHandler:nil];
}

@end
