#ifndef TDDemoAdConfig_h
#define TDDemoAdConfig_h

#import <Foundation/Foundation.h>

/** 后台 iOS 对外 Demo（td外部demoios / com.tyedo.TDAdsSDKDemo）。对内见 project/ios/TDAdsDemo。 */
static NSString * const TDDemoAppId = @"31016";

/** 插屏=621304 / Banner=621302 / 开屏=621301 / 原生=621303 / 激励=621305 */
static const long long TDDemoUnitInterstitial = 621304;
static const long long TDDemoUnitBanner = 621302;
static const long long TDDemoUnitSplash = 621301;
static const long long TDDemoUnitNative = 621303;
static const long long TDDemoUnitReward = 621305;

static inline long long TDDemoUnitForFormat(NSString *type) {
    if ([type isEqualToString:@"interstitial"]) return TDDemoUnitInterstitial;
    if ([type isEqualToString:@"banner"]) return TDDemoUnitBanner;
    if ([type isEqualToString:@"splash"]) return TDDemoUnitSplash;
    if ([type isEqualToString:@"native"]) return TDDemoUnitNative;
    return TDDemoUnitReward;
}

#endif
