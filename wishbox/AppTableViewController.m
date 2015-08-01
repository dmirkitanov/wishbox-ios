//
//  AppTableViewController.m
//  wishbox
//
//  Copyright (c) 2015 Dmitry Mirkitanov. All rights reserved.
//

#import "AppTableViewController.h"
#import "AppTableViewCell.h"
#import <RestKit/RestKit.h>
#import "AppDelegate.h"
#import <SDWebImage/SDWebImageManager.h>

#import "Wishlist.h"
#import "App.h"

typedef NS_ENUM(NSInteger, AppPriceType) {
    kAppPriceTypeOnSale = 0,
    kAppPriceTypeFree,
    kAppPriceTypePaid,
    kAppPriceTypeLoading
};

@interface AppTableViewController ()

@property (nonatomic, strong, readwrite) UIRefreshControl *refreshControl;
@property (nonatomic, strong, readwrite) UITableViewController *tableViewController;
@property (nonatomic, weak, readwrite) UITableView *tableView;

@property (nonatomic, strong, readwrite) NSMutableDictionary *sections;
@property (nonatomic, strong, readwrite) NSMutableDictionary *sectionToAppPriceTypeMap;

@end

@implementation AppTableViewController

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.sections = [NSMutableDictionary dictionary];
    self.sectionToAppPriceTypeMap = [NSMutableDictionary dictionary];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.tableViewController = [[UITableViewController alloc] init];
    self.tableViewController.tableView.delegate = self;
    self.tableViewController.tableView.dataSource = self;
    [self addChildViewController:self.tableViewController];
    [self.view addSubview:self.tableViewController.view];
    
    [self.tableViewController.view mas_makeConstraints:^(MASConstraintMaker *make) {
        if (self.pinToLayoutGuide) {
            UIView *topLayoutGuide = (id)self.topLayoutGuide;
            make.top.equalTo(topLayoutGuide.mas_bottom);
        } else {
            make.top.equalTo(self.view);
        }
        make.left.equalTo(self.view);
        make.right.equalTo(self.view);
        make.bottom.equalTo(self.view);
    }];
    
    [self.tableViewController didMoveToParentViewController:self];

    self.tableView = self.tableViewController.tableView;
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
    self.tableViewController.refreshControl = self.refreshControl;
    
    [self.tableView registerNib:[UINib nibWithNibName:@"AppTableViewCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"AppTableViewCell"];
}

- (void)refresh:(id)sender {
    
}

- (App *)appForIndexPath:(NSIndexPath *)indexPath {
    NSNumber *appPriceType = self.sectionToAppPriceTypeMap[@(indexPath.section)];
    App *app = self.sections[appPriceType][indexPath.row];

    return app;
}

- (void)updateFromWishlist:(Wishlist *)wishlist {
    [self updateFromWishlist:wishlist reloadData:YES];
}

- (void)updateFromWishlist:(Wishlist *)wishlist reloadData:(BOOL)reloadData {
    [self.sections removeAllObjects];
    [self.sectionToAppPriceTypeMap removeAllObjects];
    
    NSMutableArray *sectionToAppPriceTypeMapArray = [NSMutableArray array];

    for (App *app in wishlist.apps) {
        AppPriceType appPriceType;
        if (!app.price) {
            appPriceType = kAppPriceTypeLoading;
        } else if ([app.price compare:app.prevPrice] == NSOrderedAscending) {
            appPriceType = kAppPriceTypeOnSale;
        } else if ([app.price compare:app.prevPrice] == NSOrderedSame && [app.price isEqualToNumber:@(0)]) {
            appPriceType = kAppPriceTypeFree;
        } else {
            appPriceType = kAppPriceTypePaid;
        }
        
        if (![self.sections objectForKey:@(appPriceType)]) {
            self.sections[@(appPriceType)] = [NSMutableArray array];
            [sectionToAppPriceTypeMapArray addObject:@(appPriceType)];
        }
        [self.sections[@(appPriceType)] addObject:app];
    }
    
    NSInteger section = 0;
    NSArray *sortedAvailableAppPriceTypes = [sectionToAppPriceTypeMapArray sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES]]];
    for (NSNumber *item in sortedAvailableAppPriceTypes) {
        self.sections[item] = [self.sections[item] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]]];
        self.sectionToAppPriceTypeMap[@(section++)] = item;
    }
    
    if (reloadData) {
        [self.tableView reloadData];
    }
}

#pragma mark - Table View

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    AppPriceType appPriceType = [self.sectionToAppPriceTypeMap[@(section)] integerValue];
    switch (appPriceType) {
        case kAppPriceTypeOnSale:
            return NSLocalizedString(@"On Sale", nil);
            
        case kAppPriceTypeFree:
            return NSLocalizedString(@"Free", nil);
            
        case kAppPriceTypePaid:
            return NSLocalizedString(@"Paid", nil);

        case kAppPriceTypeLoading:
            return NSLocalizedString(@"Loading prices ...", nil);
    }
    
    return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.sections.allKeys.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSNumber *appPriceType = self.sectionToAppPriceTypeMap[@(section)];
    return [self.sections[appPriceType] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    AppTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AppTableViewCell" forIndexPath:indexPath];
    
    NSNumber *appPriceType = self.sectionToAppPriceTypeMap[@(indexPath.section)];
    App *app = self.sections[appPriceType][indexPath.row];
    
    cell.titleLabel.text = app.name;
    cell.categoryLabel.text = app.category;

    NSURL *iconURL = [NSURL URLWithString:app.iconUrl];
    NSString *iconCacheKey = [[SDWebImageManager sharedManager] cacheKeyForURL:iconURL];
    UIImage *cachedIconImage = [[[SDWebImageManager sharedManager] imageCache] imageFromDiskCacheForKey:iconCacheKey];
    if (cachedIconImage) {
        cell.iconImageView.image = cachedIconImage;
    } else {
        cell.iconImageView.image = [UIImage imageNamed:@"placeholder57"];
        [[SDWebImageManager sharedManager] downloadImageWithURL:iconURL options:0 progress:nil completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
            if (!finished || error)
                return;
            
            cell.iconImageView.image = image;
        }];
    }
    
    BOOL onSale = ([appPriceType integerValue] == kAppPriceTypeOnSale);
    
    cell.priceLabel.text = (onSale ? nil : app.formattedPrice);
    cell.oldPriceLabel.text = (onSale ? app.prevFormattedPrice : nil);
    cell.discountedPriceLabel.text = (onSale ? app.formattedPrice : nil);

    return cell;
}

@end
