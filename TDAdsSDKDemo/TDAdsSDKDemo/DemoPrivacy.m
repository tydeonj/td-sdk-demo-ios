#import "DemoPrivacy.h"
#import <TDAdsSDK/TDAdsSDK.h>
#import <TDAdsBase/TDPrivacyDeviceInfo.h>
#import <TDAdsBase/TDPrivacyController.h>
#if __has_include(<AppTrackingTransparency/AppTrackingTransparency.h>)
#import <AppTrackingTransparency/AppTrackingTransparency.h>
#endif

static NSString * const kPref = @"td_sdkdemo_privacy";
static NSString * const kAgreed = @"privacy_agreed";
static NSString * const kPersonal = @"personalized";
static NSString * const kOaid = @"oaid";
static NSString * const kDenyLoc = @"deny_location";
static NSString * const kDenyList = @"deny_install_list";

@interface _DemoPrivacyController : TDPrivacyController
@end
@implementation _DemoPrivacyController
- (BOOL)isCanUseLocation { return ![DemoPrivacy denyLocation]; }
- (BOOL)alist { return ![DemoPrivacy denyInstallList]; }
- (BOOL)isCanUseIdfa { return [DemoPrivacy oaidEnabled]; }
- (BOOL)isCanUseOaid { return [DemoPrivacy oaidEnabled]; }
@end

@implementation DemoPrivacy
+ (NSUserDefaults *)ud { return NSUserDefaults.standardUserDefaults; }
+ (BOOL)boolFor:(NSString *)k def:(BOOL)def {
    id v = [[self ud] objectForKey:[kPref stringByAppendingString:k]];
    return v ? [v boolValue] : def;
}
+ (void)setBool:(BOOL)v for:(NSString *)k {
    [[self ud] setBool:v forKey:[kPref stringByAppendingString:k]];
    [[self ud] synchronize];
}
+ (BOOL)isAgreed { return [self boolFor:kAgreed def:NO]; }
+ (void)setAgreed:(BOOL)v { [self setBool:v for:kAgreed]; }
+ (BOOL)personalized { return [self boolFor:kPersonal def:YES]; }
+ (BOOL)oaidEnabled { return [self boolFor:kOaid def:YES]; }
+ (BOOL)denyLocation { return [self boolFor:kDenyLoc def:NO]; }
+ (BOOL)denyInstallList { return [self boolFor:kDenyList def:NO]; }
+ (void)setPersonalized:(BOOL)v { [self setBool:v for:kPersonal]; }
+ (void)setOaidEnabled:(BOOL)v { [self setBool:v for:kOaid]; }
+ (void)setDenyLocation:(BOOL)v { [self setBool:v for:kDenyLoc]; }
+ (void)setDenyInstallList:(BOOL)v { [self setBool:v for:kDenyList]; }

+ (void)applySampleDefaults {
    [self setAgreed:YES];
    [self setPersonalized:YES];
    [self setOaidEnabled:YES];
    [self setDenyLocation:NO];
    [self setDenyInstallList:NO];
}
+ (void)applyBeforeInit {
    NSMutableArray *deny = [NSMutableArray new];
    if ([self denyLocation]) [deny addObject:TDPrivacyKeyLocation];
    if ([self denyInstallList]) [deny addObject:TDPrivacyKeyAppInstallList];
    if (deny.count) [TDAdsSDK deniedUploadDeviceInfo:deny];
    [TDAdsSDK setAuthUID:[self oaidEnabled]];
    [TDAdsSDK setOpenPersonalizedAd:[self personalized]];
    [TDAdsSDK setPrivacyController:[_DemoPrivacyController new]];
}
+ (void)applyAfterInit {
    [TDAdsSDK setPrivacyUserAgree:[self isAgreed]];
    [TDAdsSDK setOpenPersonalizedAd:[self personalized]];
    [TDAdsSDK setAuthUID:[self oaidEnabled]];
}
+ (void)requestTrackingThen:(void (^)(void))done {
    void (^finish)(void) = ^{
        if (done) done();
    };
    if (![self oaidEnabled]) {
        finish();
        return;
    }
#if __has_include(<AppTrackingTransparency/AppTrackingTransparency.h>)
    if (@available(iOS 14, *)) {
        ATTrackingManagerAuthorizationStatus st = ATTrackingManager.trackingAuthorizationStatus;
        if (st != ATTrackingManagerAuthorizationStatusNotDetermined) {
            finish();
            return;
        }
        [ATTrackingManager requestTrackingAuthorizationWithCompletionHandler:^(ATTrackingManagerAuthorizationStatus status) {
            (void)status;
            dispatch_async(dispatch_get_main_queue(), finish);
        }];
        return;
    }
#endif
    finish();
}
+ (NSString *)statusLine {
    return [NSString stringWithFormat:@"agree=%d personal=%d oaid=%d denyLoc=%d denyList=%d",
            [self isAgreed], [self personalized], [self oaidEnabled],
            [self denyLocation], [self denyInstallList]];
}
@end
