#import "DemoIntegrationCheck.h"
#import <TDAdsBase/TDIntegration.h>

@implementation DemoIntegrationCheck

+ (NSString *)dump {
    NSMutableArray<NSString *> *lines = [NSMutableArray new];
    [lines addObject:@"== TD integration check =="];

    NSArray *adapters = @[
        @[@"jdsdk", @"TDJdsdkReward"],
        @[@"adgain", @"TDAdgainReward"],
        @[@"ltmb", @"TDLtmbReward"],
    ];
    for (NSArray *row in adapters) {
        BOOL ok = [TDIntegration isClassPresent:row[1]];
        [lines addObject:[NSString stringWithFormat:@"adapter %-16s %@  %@",
                          [row[0] UTF8String], row[1], ok ? @"LINKED" : @"missing"]];
    }

    NSArray *peers = @[
        @[@"jdsdk", @"JinDaiSDKManager"],
        @[@"adgain", @"AdGainSDKConfig"],
        @[@"ltmb", @"LMAdSDK"],
    ];
    for (NSArray *row in peers) {
        BOOL ok = [TDIntegration isClassPresent:row[1]];
        [lines addObject:[NSString stringWithFormat:@"peer    %-16s %@  %@",
                          [row[0] UTF8String], row[1], ok ? @"LINKED" : @"missing"]];
    }

    NSString *text = [lines componentsJoinedByString:@"\n"];
    NSLog(@"%@", text);
    return text;
}

@end
