#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DemoPrivacy : NSObject
+ (BOOL)isAgreed;
+ (void)setAgreed:(BOOL)v;
+ (BOOL)personalized;
+ (BOOL)oaidEnabled;
+ (BOOL)denyLocation;
+ (BOOL)denyInstallList;
+ (void)setPersonalized:(BOOL)v;
+ (void)setOaidEnabled:(BOOL)v;
+ (void)setDenyLocation:(BOOL)v;
+ (void)setDenyInstallList:(BOOL)v;
+ (void)applySampleDefaults;
+ (void)applyBeforeInit;
+ (void)applyAfterInit;
+ (void)requestTrackingThen:(void (^)(void))done;
+ (NSString *)statusLine;
@end

NS_ASSUME_NONNULL_END
