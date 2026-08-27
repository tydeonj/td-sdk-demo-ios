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

@interface FormatViewController () <TDRewardListener, TDInterstitialListener, TDSplashListener, TDBannerListener, TDNativeListener>
@property (nonatomic, strong) id ad;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UITextField *unitField;
@property (nonatomic, strong) UITextField *floorField;
@property (nonatomic, strong) UITextView *logView;
@property (nonatomic, strong) UIView *adContainer;
@property (nonatomic, strong) NSLayoutConstraint *adContainerHeight;
@property (nonatomic, strong) UIView *splashOverlay;
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
        [a setAdListener:self]; [a setContainer:self.splashOverlay]; self.ad = a;
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
    if ([t isEqualToString:@"banner"]) {
        self.adContainer.hidden = NO;
        self.adContainerHeight.constant = 200;
    } else if ([t isEqualToString:@"native"]) {
        self.adContainer.hidden = NO;
        self.adContainerHeight.constant = 280;
    } else {
        self.adContainer.hidden = YES;
        self.adContainerHeight.constant = 0;
    }
}

- (void)showSplashOverlayThenReleaseIfUnused {
    self.splashOverlay.backgroundColor = UIColor.clearColor;
    self.splashOverlay.alpha = 1;
    self.splashOverlay.userInteractionEnabled = YES;
    [self.view layoutIfNeeded];
    [self.ad showAdFrom:self container:self.splashOverlay sceneId:@"demo_scene"];
    if (self.splashOverlay.subviews.count == 0) {
        [self hideSplashOverlay];
        return;
    }
    self.splashOverlay.backgroundColor = UIColor.blackColor;
}

- (void)hideSplashOverlay {
    for (UIView *sub in [self.splashOverlay.subviews copy]) {
        [sub removeFromSuperview];
    }
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
    }
}

- (void)assembleNativeIfNeeded:(TDAdInfo *)info {
    if (info.renderType != TDRenderTypeSelfRender) return;
    TDNativeMaterial *m = info.nativeMaterial;
    for (UIView *sub in [self.adContainer.subviews copy]) {
        [sub removeFromSuperview];
    }
    UIStackView *stack = [UIStackView new];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 4;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    UILabel *title = [UILabel new];
    title.text = m.title ?: @"";
    title.font = [UIFont boldSystemFontOfSize:16];
    title.userInteractionEnabled = YES;
    title.accessibilityIdentifier = TDNativeMaterial.tagTitle;
    UILabel *desc = [UILabel new];
    desc.text = m.desc ?: @"";
    desc.font = [UIFont systemFontOfSize:13];
    desc.numberOfLines = 2;
    desc.userInteractionEnabled = YES;
    desc.accessibilityIdentifier = TDNativeMaterial.tagDesc;
    UILabel *cta = [UILabel new];
    cta.text = m.cta.length ? m.cta : @"查看详情";
    cta.font = [UIFont systemFontOfSize:14];
    cta.textColor = UIColor.systemBlueColor;
    cta.userInteractionEnabled = YES;
    cta.accessibilityIdentifier = TDNativeMaterial.tagCta;
    [stack addArrangedSubview:title];
    [stack addArrangedSubview:desc];
    [stack addArrangedSubview:cta];
    if (m.imageUrl.length) {
        [stack addArrangedSubview:[self nativeImageView:m.imageUrl tag:TDNativeMaterial.tagImage height:120]];
    }
    [self.adContainer addSubview:stack];
    [NSLayoutConstraint activateConstraints:@[
        [stack.leadingAnchor constraintEqualToAnchor:self.adContainer.leadingAnchor constant:12],
        [stack.trailingAnchor constraintEqualToAnchor:self.adContainer.trailingAnchor constant:-12],
        [stack.topAnchor constraintEqualToAnchor:self.adContainer.topAnchor constant:8],
    ]];
    [self append:@"assembled self_render title=%@ img=%@", m.title ?: @"", m.imageUrl ?: @""];
}

- (UIImageView *)nativeImageView:(NSString *)url tag:(NSString *)tag height:(CGFloat)h {
    UIImageView *img = [UIImageView new];
    img.contentMode = UIViewContentModeScaleAspectFill;
    img.clipsToBounds = YES;
    img.backgroundColor = [UIColor colorWithWhite:0.92 alpha:1];
    img.userInteractionEnabled = YES;
    img.accessibilityIdentifier = tag;
    [img.heightAnchor constraintEqualToConstant:h].active = YES;
    NSURL *u = [NSURL URLWithString:url ?: @""];
    if (!u) return img;
    [[[NSURLSession sharedSession] dataTaskWithURL:u completionHandler:^(NSData *data, NSURLResponse *r, NSError *e) {
        if (!data || e) return;
        UIImage *im = [UIImage imageWithData:data];
        if (!im) return;
        dispatch_async(dispatch_get_main_queue(), ^{ img.image = im; });
    }] resume];
    return img;
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
