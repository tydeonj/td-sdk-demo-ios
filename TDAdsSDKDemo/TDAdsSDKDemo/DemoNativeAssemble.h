#import <UIKit/UIKit.h>
@class TDAdInfo;

NS_ASSUME_NONNULL_BEGIN

/** Demo 自渲染：按信息流大图卡片拼（图标+标题+广告标 / 主图 / CTA），再 Show。 */
@interface DemoNativeAssemble : NSObject
+ (BOOL)assemble:(nullable TDAdInfo *)info into:(nullable UIView *)container;
@end

NS_ASSUME_NONNULL_END
