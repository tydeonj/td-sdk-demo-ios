#import "FormatViewController.h"
#import <TDAdsSDK/TDReward.h>
#import <TDAdsSDK/TDInterstitial.h>
#import <TDAdsSDK/TDSplash.h>
#import <TDAdsSDK/TDBanner.h>
#import <TDAdsSDK/TDNative.h>
#import <TDAdsSDK/TDRewardListener.h>
#import <TDAdsSDK/TDInterstitialListener.h>
#import <TDAdsSDK/TDSplashListener.h>
#import <TDAdsSDK/TDBannerListener.h>
#import <TDAdsSDK/TDNativeListener.h>
#import <TDAdsSDK/TDAdInfo.h>
#import <TDAdsSDK/TDAdsSDK.h>
#import <TDAdsBase/TDRenderType.h>
#import <TDAdsBase/TDNativeMaterial.h>
#import <TDAdsBase/TDError.h>
#import "DemoNativeAssemble.h"

@interface FormatViewController () <TDRewardListener, TDInterstitialListener, TDSplashListener, TDBannerListener, TDNativeListener>
@property (nonatomic, strong) id ad;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UITextField *unitField;
@property (nonatomic, strong) UITextField *floorField;
@property (nonatomic, strong) UITextView *logView;
@property (nonatomic, strong) UIView *adContainer;
@property (nonatomic, strong) NSLayoutConstraint *adContainerHeight;
@property (nonatomic, strong) UILabel *splashHint;
@property (nonatomic, strong) UIView *splashPreview;
@property (nonatomic, strong) NSLayoutConstraint *splashPreviewHeight;
@property (nonatomic, strong) UIView *splashOverlay;
@property (nonatomic, strong) UIView *splashAdArea;
@property (nonatomic, strong) UIView *splashBottomBar;
@property (nonatomic, strong) NSDateFormatter *timeFmt;
@property (nonatomic, strong) TDAdInfo *lastNativeInfo;
@end

@implementation FormatViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = [self displayTitle];
    self.view.backgroundColor = UIColor.systemBackgroundColor;
    self.timeFmt = [NSDateFormatter new];
    self.timeFmt.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    self.timeFmt.dateFormat = @"HH:mm:ss.SSS";

    UIStackView *stack = [UIStackView new];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 10;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:stack];
    [NSLayoutConstraint activateConstraints:@[
        [stack.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:16],
        [stack.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16],
        [stack.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16],
    ]];

    self.titleLabel = [UILabel new];
    self.titleLabel.text = [self displayTitle];
    self.titleLabel.font = [UIFont boldSystemFontOfSize:20];
    [stack addArrangedSubview:self.titleLabel];

    self.unitField = [UITextField new];
    self.unitField.borderStyle = UITextBorderStyleRoundedRect;
    self.unitField.placeholder = @"adId (long)";
    self.unitField.keyboardType = UIKeyboardTypeNumberPad;
    self.unitField.font = [UIFont systemFontOfSize:14];
    if (self.adUnitId > 0) {
        self.unitField.text = [NSString stringWithFormat:@"%lld", self.adUnitId];
    }
    [stack addArrangedSubview:self.unitField];

    self.floorField = [UITextField new];
    self.floorField.borderStyle = UITextBorderStyleRoundedRect;
    self.floorField.placeholder = @"动态底价(分)，空=不设，0=清除";
    self.floorField.keyboardType = UIKeyboardTypeNumberPad;
    self.floorField.font = [UIFont systemFontOfSize:14];
    [stack addArrangedSubview:self.floorField];

    UIStackView *btns = [[UIStackView alloc] init];
    btns.axis = UILayoutConstraintAxisHorizontal;
    btns.spacing = 8;
    btns.distribution = UIStackViewDistributionFillEqually;
    [btns addArrangedSubview:[self btn:@"Load" action:@selector(doLoad)]];
    [btns addArrangedSubview:[self btn:@"Show" action:@selector(doShow)]];
    [btns addArrangedSubview:[self btn:@"isReady" action:@selector(doReady)]];
    [stack addArrangedSubview:btns];

    self.splashHint = [UILabel new];
    self.splashHint.font = [UIFont systemFontOfSize:12];
    self.splashHint.textColor = [UIColor colorWithWhite:0.4 alpha:1];
    self.splashHint.numberOfLines = 0;
    self.splashHint.text = @"开屏两段：上方广告区，下方白色底部条（logo / 应用名）";
    [stack addArrangedSubview:self.splashHint];

    self.splashPreview = [UIView new];
    self.splashPreview.backgroundColor = [UIColor colorWithWhite:0.15 alpha:1];
    self.splashPreview.clipsToBounds = YES;
    self.splashPreview.layer.cornerRadius = 8;
    self.splashPreviewHeight = [self.splashPreview.heightAnchor constraintEqualToConstant:280];
    self.splashPreviewHeight.active = YES;
    [stack addArrangedSubview:self.splashPreview];

    self.adContainer = [UIView new];
    self.adContainer.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1];
    self.adContainerHeight = [self.adContainer.heightAnchor constraintEqualToConstant:50];
    self.adContainerHeight.active = YES;
    [stack addArrangedSubview:self.adContainer];

    self.logView = [UITextView new];
    self.logView.editable = NO;
    self.logView.selectable = YES;
    self.logView.font = [UIFont systemFontOfSize:12];
    self.logView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.logView];
    [NSLayoutConstraint activateConstraints:@[
        [self.logView.topAnchor constraintEqualToAnchor:stack.bottomAnchor constant:12],
        [self.logView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:12],
        [self.logView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-12],
        [self.logView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor],
    ]];

    self.splashOverlay = [UIView new];
    self.splashOverlay.hidden = NO;
    self.splashOverlay.alpha = 0;
    self.splashOverlay.userInteractionEnabled = NO;
    self.splashOverlay.backgroundColor = UIColor.blackColor;
    self.splashOverlay.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.splashOverlay];
    [NSLayoutConstraint activateConstraints:@[
        [self.splashOverlay.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.splashOverlay.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.splashOverlay.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.splashOverlay.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];
    [self installSplashBottomLayout];
    [self applyContainerForType];
    [self createAd];
}

- (UIButton *)btn:(NSString *)title action:(SEL)sel {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
    [b setTitle:title forState:UIControlStateNormal];
    b.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    [b addTarget:self action:sel forControlEvents:UIControlEventTouchUpInside];
    return b;
}

- (long long)unitId {
    NSString *s = [self.unitField.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    return s.longLongValue;
}

- (void)append:(NSString *)fmt, ... {
    va_list args; va_start(args, fmt);
    NSString *s = [[NSString alloc] initWithFormat:fmt arguments:args];
    va_end(args);
    NSString *line = [NSString stringWithFormat:@"%@  %@\n", [self.timeFmt stringFromDate:[NSDate date]], s];
    dispatch_async(dispatch_get_main_queue(), ^{
        self.logView.text = [self.logView.text stringByAppendingString:line];
    });
}

- (void)createAd {
    if ([self.ad respondsToSelector:@selector(onDestroy)]) [self.ad onDestroy];
    self.ad = nil;
    self.lastNativeInfo = nil;
    long long u = [self unitId];
    NSString *t = self.formatType;
    if ([t isEqualToString:@"reward"]) {
        TDReward *a = [[TDReward alloc] initWithAdUnitId:u];
        [a setAdListener:self]; self.ad = a;
    } else if ([t isEqualToString:@"interstitial"]) {
        TDInterstitial *a = [[TDInterstitial alloc] initWithAdUnitId:u];
        [a setAdListener:self]; self.ad = a;
    } else if ([t isEqualToString:@"splash"]) {
        TDSplash *a = [[TDSplash alloc] initWithAdUnitId:u];
        [a setAdListener:self]; [a setContainer:self.splashAdArea]; self.ad = a;
    } else if ([t isEqualToString:@"banner"]) {
        TDBanner *a = [[TDBanner alloc] initWithAdUnitId:u];
        [a setAdListener:self]; [a setContainer:self.adContainer]; self.ad = a;
    } else {
        TDNative *a = [[TDNative alloc] initWithAdUnitId:u];
        [a setAdListener:self]; [a setContainer:self.adContainer]; self.ad = a;
    }
    if ([self.ad respondsToSelector:@selector(setCustomParams:)]) {
        [self.ad setCustomParams:@{ @"userId": @"td_demo_user", @"channel": @"td_demo" }];
    }
    [self append:@"created unit=%lld", u];
}

- (void)applyBannerAdSizeIfNeeded {
    if (![self.formatType isEqualToString:@"banner"]) return;
    if (![self.ad respondsToSelector:@selector(setAdSize:height:)]) return;
    [self.view layoutIfNeeded];
    CGSize s = self.adContainer.bounds.size;
    if (s.width < 1 || s.height < 1) return;
    [(TDBanner *)self.ad setAdSize:(NSInteger)lround(s.width) height:(NSInteger)lround(s.height)];
}

- (void)applyBidFloor {
    NSString *raw = [self.floorField.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (raw.length == 0) return;
    NSInteger fen = raw.integerValue;
    if (fen == 0 && ![raw isEqualToString:@"0"]) {
        [self append:@"setBidFloor invalid: %@", raw];
        return;
    }
    if ([self.ad respondsToSelector:@selector(setBidFloor:)]) {
        [self.ad setBidFloor:fen];
        [self append:@"setBidFloor %ld", (long)fen];
    }
}

- (void)doLoad {
    if (![TDAdsSDK isInit]) {
        [self append:@"请先初始化 SDK"];
        return;
    }
    [self createAd];
    [self applyBidFloor];
    [self applyBannerAdSizeIfNeeded];
    [self.ad loadAd];
}

- (void)doShow {
    if (![TDAdsSDK isInit]) {
        [self append:@"请先初始化 SDK"];
        return;
    }
    NSString *t = self.formatType;
    if ([t isEqualToString:@"splash"]) {
        [self showSplashOverlayThenReleaseIfUnused];
    } else if ([t isEqualToString:@"banner"] || [t isEqualToString:@"native"]) {
        if ([t isEqualToString:@"native"]) {
            [self assembleNativeIfNeeded:self.lastNativeInfo];
        }
        [self.ad showAdFrom:self container:self.adContainer sceneId:@"demo_scene"];
    } else {
        [self.ad showAdFrom:self sceneId:@"demo_scene"];
    }
}

- (void)applyContainerForType {
    NSString *t = self.formatType;
    [self hideSplashOverlay];
    BOOL splash = [t isEqualToString:@"splash"];
    self.splashHint.hidden = !splash;
    self.splashPreview.hidden = !splash;
    self.splashPreviewHeight.constant = splash ? 280 : 0;
    if ([t isEqualToString:@"banner"]) {
        self.adContainer.hidden = NO;
        self.adContainerHeight.constant = 200;
    } else if ([t isEqualToString:@"native"]) {
        self.adContainer.hidden = NO;
        self.adContainerHeight.constant = 360;
    } else {
        self.adContainer.hidden = YES;
        self.adContainerHeight.constant = 0;
    }
}

- (void)installSplashBottomLayout {
    self.splashAdArea = [UIView new];
    self.splashAdArea.backgroundColor = [UIColor colorWithWhite:0.92 alpha:1];
    self.splashAdArea.translatesAutoresizingMaskIntoConstraints = NO;
    UILabel *areaHint = [UILabel new];
    areaHint.text = @"开屏广告区";
    areaHint.tag = 9001;
    areaHint.font = [UIFont systemFontOfSize:14];
    areaHint.textColor = [UIColor colorWithWhite:0.5 alpha:1];
    areaHint.textAlignment = NSTextAlignmentCenter;
    areaHint.translatesAutoresizingMaskIntoConstraints = NO;
    [self.splashAdArea addSubview:areaHint];
    [NSLayoutConstraint activateConstraints:@[
        [areaHint.centerXAnchor constraintEqualToAnchor:self.splashAdArea.centerXAnchor],
        [areaHint.centerYAnchor constraintEqualToAnchor:self.splashAdArea.centerYAnchor],
    ]];
    self.splashBottomBar = [self makeSplashBottomBar];
    [self layoutSplashChromeIn:self.splashPreview];
}

- (void)layoutSplashChromeIn:(UIView *)host {
    if (!host) return;
    [self.splashAdArea removeFromSuperview];
    [host addSubview:self.splashAdArea];
    [self ensureDemoSplashBarIn:host];
    CGFloat bottomH = (host == self.splashPreview)
        ? 80
        : MIN(CGRectGetHeight(UIScreen.mainScreen.bounds) * 0.20, 120);
    [NSLayoutConstraint activateConstraints:@[
        [self.splashAdArea.topAnchor constraintEqualToAnchor:host.topAnchor],
        [self.splashAdArea.leadingAnchor constraintEqualToAnchor:host.leadingAnchor],
        [self.splashAdArea.trailingAnchor constraintEqualToAnchor:host.trailingAnchor],
        [self.splashAdArea.bottomAnchor constraintEqualToAnchor:self.splashBottomBar.topAnchor],
        [self.splashBottomBar.leadingAnchor constraintEqualToAnchor:host.leadingAnchor],
        [self.splashBottomBar.trailingAnchor constraintEqualToAnchor:host.trailingAnchor],
        [self.splashBottomBar.bottomAnchor constraintEqualToAnchor:host.bottomAnchor],
        [self.splashBottomBar.heightAnchor constraintEqualToConstant:bottomH],
    ]];
}

- (void)ensureDemoSplashBarIn:(UIView *)host {
    BOOL stolen = self.splashBottomBar.superview
        && self.splashBottomBar.superview != self.splashPreview
        && self.splashBottomBar.superview != self.splashOverlay;
    if (!self.splashBottomBar || stolen) {
        self.splashBottomBar = [self makeSplashBottomBar];
    }
    if (self.splashBottomBar.superview != host) {
        [self.splashBottomBar removeFromSuperview];
        [host addSubview:self.splashBottomBar];
    }
}

- (UIView *)makeSplashBottomBar {
    UIView *bar = [UIView new];
    bar.backgroundColor = UIColor.whiteColor;
    bar.translatesAutoresizingMaskIntoConstraints = NO;
    UILabel *title = [UILabel new];
    title.text = @"TD Ads";
    title.font = [UIFont boldSystemFontOfSize:18];
    title.textColor = [UIColor colorWithWhite:0.15 alpha:1];
    title.textAlignment = NSTextAlignmentCenter;
    title.translatesAutoresizingMaskIntoConstraints = NO;
    UILabel *sub = [UILabel new];
    sub.text = @"开屏底部区域";
    sub.font = [UIFont systemFontOfSize:12];
    sub.textColor = [UIColor colorWithWhite:0.4 alpha:1];
    sub.textAlignment = NSTextAlignmentCenter;
    sub.translatesAutoresizingMaskIntoConstraints = NO;
    [bar addSubview:title];
    [bar addSubview:sub];
    [NSLayoutConstraint activateConstraints:@[
        [title.centerXAnchor constraintEqualToAnchor:bar.centerXAnchor],
        [title.centerYAnchor constraintEqualToAnchor:bar.centerYAnchor constant:-10],
        [sub.centerXAnchor constraintEqualToAnchor:bar.centerXAnchor],
        [sub.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:4],
    ]];
    return bar;
}

- (void)showSplashOverlayThenReleaseIfUnused {
    [self layoutSplashChromeIn:self.splashOverlay];
    self.splashOverlay.backgroundColor = UIColor.blackColor;
    self.splashOverlay.alpha = 1;
    self.splashOverlay.userInteractionEnabled = YES;
    [self.view layoutIfNeeded];
    [self.ad showAdFrom:self container:self.splashAdArea sceneId:@"demo_scene"];
    if (self.splashBottomBar.superview != self.splashOverlay) {
        [self layoutSplashChromeIn:self.splashOverlay];
    }
    NSString *net = [[self.ad getAdInfo] networkName] ?: @"?";
    [self append:@"splash net=%@：上面广告区、下面白条「TD Ads / 开屏底部区域」", net];
}

- (void)hideSplashOverlay {
    for (UIView *sub in [self.splashAdArea.subviews copy]) {
        if (sub.tag == 9001) continue;
        [sub removeFromSuperview];
    }
    [self layoutSplashChromeIn:self.splashPreview];
    self.splashOverlay.alpha = 0;
    self.splashOverlay.userInteractionEnabled = NO;
}

- (void)clearAdContainer {
    for (UIView *sub in [self.adContainer.subviews copy]) {
        [sub removeFromSuperview];
    }
}

- (void)doReady { [self append:@"isReady=%d", [self.ad isReady]]; }

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (self.presentedViewController) return;
    if (self.isMovingFromParentViewController || self.isBeingDismissed) {
        if ([self.ad respondsToSelector:@selector(onDestroy)]) [self.ad onDestroy];
        self.ad = nil;
    }
}

- (void)onAdLoaded:(TDAdInfo *)info {
    if ([self.formatType isEqualToString:@"native"]) {
        self.lastNativeInfo = info;
        [self append:@"onAdLoaded %@ renderType=%@", info, TDRenderTypeName(info.renderType)];
    } else {
        [self append:@"onAdLoaded %@", info];
        if ([self.formatType isEqualToString:@"splash"]) {
            if (self.splashOverlay.alpha < 0.5) {
                [self layoutSplashChromeIn:self.splashPreview];
            }
            [self append:@"开屏底部条：页上白条「TD Ads」即 bottomView"];
        }
    }
}

- (void)assembleNativeIfNeeded:(TDAdInfo *)info {
    if (![DemoNativeAssemble assemble:info into:self.adContainer]) return;
    TDNativeMaterial *m = info.nativeMaterial;
    [self append:@"assembled self_render title=%@ img=%@", m.title ?: @"", m.imageUrl ?: @""];
}

- (void)onAdLoadFailed:(TDError *)error { [self append:@"onAdLoadFailed %@", error]; }
- (void)onAdIsLoading { [self append:@"onAdIsLoading"]; }
- (void)onBiddingStart:(TDAdInfo *)info {
    [self append:@"onBiddingStart %@", info];
}
- (void)onBiddingEnd:(TDAdInfo *)info error:(TDError *)error {
    [self append:@"onBiddingEnd %@ %@", info, error ?: @"ok"];
}
- (void)onAdAllLoaded:(BOOL)isSuccess { [self append:@"onAdAllLoaded %@", isSuccess ? @"true" : @"false"]; }
- (void)onAdImpression:(TDAdInfo *)info { [self append:@"onAdImpression"]; }
- (void)onAdClicked:(TDAdInfo *)info { [self append:@"onAdClicked"]; }
- (void)onAdClosed:(TDAdInfo *)info {
    if ([self.formatType isEqualToString:@"splash"]) [self hideSplashOverlay];
    if ([self.formatType isEqualToString:@"banner"] || [self.formatType isEqualToString:@"native"]) {
        [self clearAdContainer];
    }
    [self append:@"onAdClosed"];
}
- (void)onAdShowFailed:(TDError *)error {
    if ([self.formatType isEqualToString:@"splash"]) [self hideSplashOverlay];
    [self append:@"onAdShowFailed %@", error];
}
- (void)onVideoStart:(TDAdInfo *)info { [self append:@"onVideoStart"]; }
- (void)onVideoComplete:(TDAdInfo *)info { [self append:@"onVideoComplete"]; }
- (void)onAdReward:(TDAdInfo *)info { [self append:@"onAdReward"]; }

- (NSString *)displayTitle {
    NSString *t = self.formatType ?: @"";
    if ([t isEqualToString:@"reward"]) return @"激励视频";
    if ([t isEqualToString:@"interstitial"]) return @"插屏";
    if ([t isEqualToString:@"splash"]) return @"开屏";
    if ([t isEqualToString:@"banner"]) return @"横幅 Banner";
    if ([t isEqualToString:@"native"]) return @"原生";
    return t.length ? t : @"广告";
}
@end
