#import "DemoNativeAssemble.h"
#if __has_include(<TDAdsSDK/TDAdInfo.h>)
#import <TDAdsSDK/TDAdInfo.h>
#import <TDAdsBase/TDNativeMaterial.h>
#import <TDAdsBase/TDRenderType.h>
#else
#import "TDAdInfo.h"
#import "TDNativeMaterial.h"
#import "TDRenderType.h"
#endif

@implementation DemoNativeAssemble

+ (BOOL)assemble:(TDAdInfo *)info into:(UIView *)container {
    if (!info || !container || info.renderType != TDRenderTypeSelfRender) return NO;
    TDNativeMaterial *m = info.nativeMaterial;
    for (UIView *sub in [container.subviews copy]) {
        [sub removeFromSuperview];
    }

    UIView *card = [UIView new];
    card.backgroundColor = UIColor.whiteColor;
    card.layer.cornerRadius = 8;
    card.layer.borderWidth = 1.0 / UIScreen.mainScreen.scale;
    card.layer.borderColor = [UIColor colorWithWhite:0.91 alpha:1].CGColor;
    card.translatesAutoresizingMaskIntoConstraints = NO;
    [container addSubview:card];
    [NSLayoutConstraint activateConstraints:@[
        [card.leadingAnchor constraintEqualToAnchor:container.leadingAnchor],
        [card.trailingAnchor constraintEqualToAnchor:container.trailingAnchor],
        [card.topAnchor constraintEqualToAnchor:container.topAnchor],
        [card.bottomAnchor constraintLessThanOrEqualToAnchor:container.bottomAnchor],
    ]];

    UIStackView *stack = [UIStackView new];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 10;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:stack];
    [NSLayoutConstraint activateConstraints:@[
        [stack.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:12],
        [stack.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-12],
        [stack.topAnchor constraintEqualToAnchor:card.topAnchor constant:12],
        [stack.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-12],
    ]];

    UIStackView *header = [UIStackView new];
    header.axis = UILayoutConstraintAxisHorizontal;
    header.alignment = UIStackViewAlignmentCenter;
    header.spacing = 10;

    UIImageView *icon = [self imageView:m.iconUrl tag:TDNativeMaterial.tagIcon height:40];
    [icon.widthAnchor constraintEqualToConstant:40].active = YES;
    icon.layer.cornerRadius = 6;
    [header addArrangedSubview:icon];

    UIStackView *texts = [UIStackView new];
    texts.axis = UILayoutConstraintAxisVertical;
    texts.spacing = 2;
    [texts setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];

    UIStackView *titleRow = [UIStackView new];
    titleRow.axis = UILayoutConstraintAxisHorizontal;
    titleRow.alignment = UIStackViewAlignmentCenter;
    titleRow.spacing = 6;
    UILabel *title = [UILabel new];
    title.text = m.title ?: @"";
    title.font = [UIFont boldSystemFontOfSize:15];
    title.textColor = [UIColor colorWithWhite:0.13 alpha:1];
    title.numberOfLines = 2;
    title.userInteractionEnabled = YES;
    title.accessibilityIdentifier = TDNativeMaterial.tagTitle;
    [title setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    [titleRow addArrangedSubview:title];
    UILabel *badge = [UILabel new];
    badge.text = @"广告";
    badge.font = [UIFont systemFontOfSize:10];
    badge.textColor = [UIColor colorWithWhite:0.62 alpha:1];
    badge.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1];
    badge.textAlignment = NSTextAlignmentCenter;
    badge.layer.cornerRadius = 2;
    badge.clipsToBounds = YES;
    [badge.widthAnchor constraintGreaterThanOrEqualToConstant:28].active = YES;
    [badge.heightAnchor constraintEqualToConstant:16].active = YES;
    [badge setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    [titleRow addArrangedSubview:badge];
    [texts addArrangedSubview:titleRow];

    if (m.desc.length) {
        UILabel *desc = [UILabel new];
        desc.text = m.desc;
        desc.font = [UIFont systemFontOfSize:12];
        desc.textColor = [UIColor colorWithWhite:0.46 alpha:1];
        desc.numberOfLines = 2;
        desc.userInteractionEnabled = YES;
        desc.accessibilityIdentifier = TDNativeMaterial.tagDesc;
        [texts addArrangedSubview:desc];
    }
    [header addArrangedSubview:texts];
    [stack addArrangedSubview:header];

    if (m.imageUrl.length) {
        UIImageView *img = [self imageView:m.imageUrl tag:TDNativeMaterial.tagImage height:180];
        img.layer.cornerRadius = 6;
        [stack addArrangedSubview:img];
    }

    UILabel *cta = [UILabel new];
    cta.text = m.cta.length ? m.cta : @"查看详情";
    cta.font = [UIFont boldSystemFontOfSize:15];
    cta.textColor = UIColor.whiteColor;
    cta.textAlignment = NSTextAlignmentCenter;
    cta.backgroundColor = [UIColor colorWithRed:0.082 green:0.396 blue:0.753 alpha:1];
    cta.layer.cornerRadius = 6;
    cta.clipsToBounds = YES;
    cta.userInteractionEnabled = YES;
    cta.accessibilityIdentifier = TDNativeMaterial.tagCta;
    [cta.heightAnchor constraintEqualToConstant:40].active = YES;
    [stack addArrangedSubview:cta];
    return YES;
}

+ (UIImageView *)imageView:(NSString *)url tag:(NSString *)tag height:(CGFloat)h {
    UIImageView *img = [UIImageView new];
    img.contentMode = UIViewContentModeScaleAspectFill;
    img.clipsToBounds = YES;
    img.backgroundColor = [UIColor colorWithWhite:0.94 alpha:1];
    img.userInteractionEnabled = YES;
    img.accessibilityIdentifier = tag;
    [img.heightAnchor constraintEqualToConstant:h].active = YES;
    if (url.length == 0) return img;
    NSURL *u = [NSURL URLWithString:url];
    if (!u) return img;
    [[[NSURLSession sharedSession] dataTaskWithURL:u completionHandler:^(NSData *data, NSURLResponse *r, NSError *e) {
        if (!data || e) return;
        UIImage *im = [UIImage imageWithData:data];
        if (!im) return;
        dispatch_async(dispatch_get_main_queue(), ^{ img.image = im; });
    }] resume];
    return img;
}

@end
