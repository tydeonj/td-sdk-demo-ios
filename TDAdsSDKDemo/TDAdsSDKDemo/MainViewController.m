#import "MainViewController.h"
#import "FormatViewController.h"
#import "AdConfig.h"
#import "DemoIntegrationCheck.h"
#import "DemoPrivacy.h"
#import <TDAdsSDK/TDAdsSDK.h>
#import <TDAdsSDK/TDInitListener.h>
#import <TDAdsBase/TDError.h>

@interface MainViewController () <TDInitListener>
@property (nonatomic, strong) UIStackView *stack;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *statusLabel;
@end

@implementation MainViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"TD 接入示例";
    self.view.backgroundColor = UIColor.systemBackgroundColor;

    UIScrollView *scroll = [UIScrollView new];
    scroll.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:scroll];
    [NSLayoutConstraint activateConstraints:@[
        [scroll.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [scroll.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [scroll.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [scroll.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];

    self.stack = [[UIStackView alloc] init];
    self.stack.axis = UILayoutConstraintAxisVertical;
    self.stack.spacing = 12;
    self.stack.translatesAutoresizingMaskIntoConstraints = NO;
    [scroll addSubview:self.stack];
    [NSLayoutConstraint activateConstraints:@[
        [self.stack.topAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.topAnchor constant:16],
        [self.stack.leadingAnchor constraintEqualToAnchor:scroll.frameLayoutGuide.leadingAnchor constant:20],
        [self.stack.trailingAnchor constraintEqualToAnchor:scroll.frameLayoutGuide.trailingAnchor constant:-20],
        [self.stack.bottomAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.bottomAnchor constant:-24],
        [self.stack.widthAnchor constraintEqualToAnchor:scroll.frameLayoutGuide.widthAnchor constant:-40],
    ]];

    self.titleLabel = [UILabel new];
    self.titleLabel.font = [UIFont boldSystemFontOfSize:22];
    [self.stack addArrangedSubview:self.titleLabel];

    UILabel *hint = [UILabel new];
    hint.numberOfLines = 0;
    hint.font = [UIFont systemFontOfSize:13];
    hint.textColor = UIColor.secondaryLabelColor;
    hint.text = @"先初始化，再按广告类型 Load / Show。广告位只改 AdConfig。";
    [self.stack addArrangedSubview:hint];

    self.statusLabel = [UILabel new];
    self.statusLabel.numberOfLines = 0;
    self.statusLabel.font = [UIFont systemFontOfSize:14];
    self.statusLabel.textColor = [UIColor colorWithRed:0.08 green:0.40 blue:0.75 alpha:1];
    [self.stack addArrangedSubview:self.statusLabel];

    [self.stack addArrangedSubview:[self btn:@"初始化 SDK" action:@selector(doInit)]];
    [self.stack addArrangedSubview:[self section:@"广告类型"]];
    for (NSArray *item in @[
        @[@"激励视频", @"reward"],
        @[@"插屏", @"interstitial"],
        @[@"开屏", @"splash"],
        @[@"横幅 Banner", @"banner"],
        @[@"原生", @"native"],
    ]) {
        UIButton *b = [self btn:item[0] action:@selector(openFormat:)];
        b.accessibilityIdentifier = item[1];
        [self.stack addArrangedSubview:b];
    }
    [self.stack addArrangedSubview:[self btn:@"清除广告缓存" action:@selector(doClearCache)]];

    [self refreshStatus];
}

- (UILabel *)section:(NSString *)text {
    UILabel *lab = [UILabel new];
    lab.text = text;
    lab.font = [UIFont boldSystemFontOfSize:16];
    return lab;
}

- (UIButton *)btn:(NSString *)title action:(SEL)sel {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
    [b setTitle:title forState:UIControlStateNormal];
    b.titleLabel.font = [UIFont boldSystemFontOfSize:17];
    [b addTarget:self action:sel forControlEvents:UIControlEventTouchUpInside];
    return b;
}

- (void)refreshStatus {
    self.titleLabel.text = [NSString stringWithFormat:@"TD iOS SDK  %@", [TDAdsSDK sdkVersion]];
    self.statusLabel.text = [TDAdsSDK isInit]
        ? [NSString stringWithFormat:@"已初始化  v%@", [TDAdsSDK sdkVersion]]
        : @"未初始化";
}

- (void)setStatus:(NSString *)text {
    self.statusLabel.text = text;
}

- (void)doInit {
    [self setStatus:@"初始化中…"];
    [DemoPrivacy applySampleDefaults];
    __weak typeof(self) weakSelf = self;
    [DemoPrivacy requestTrackingThen:^{
        [DemoPrivacy applyBeforeInit];
        [TDAdsSDK initSdkWithAppId:TDDemoAppId listener:weakSelf];
    }];
}
- (void)onSuccess {
    [DemoPrivacy applyAfterInit];
    [DemoIntegrationCheck dump];
    [self refreshStatus];
}
- (void)onFailed:(TDError *)error {
    [self setStatus:[NSString stringWithFormat:@"初始化失败  %@", error]];
}
- (void)doClearCache {
    for (NSNumber *u in @[@(TDDemoUnitInterstitial), @(TDDemoUnitBanner), @(TDDemoUnitSplash),
                          @(TDDemoUnitNative), @(TDDemoUnitReward)]) {
        [TDAdsSDK clearCache:u.longLongValue];
    }
    [self setStatus:@"已清除缓存"];
}
- (void)openFormat:(UIButton *)sender {
    FormatViewController *vc = [FormatViewController new];
    vc.formatType = sender.accessibilityIdentifier;
    vc.adUnitId = TDDemoUnitForFormat(sender.accessibilityIdentifier);
    [self.navigationController pushViewController:vc animated:YES];
}
@end
