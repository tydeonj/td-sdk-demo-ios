#import "AppDelegate.h"
#import "MainViewController.h"
#import <TDAdsSDK/TDAdsSDK.h>

@implementation AppDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [TDAdsSDK setDebugMode:YES];
    [TDAdsSDK setLocalMockMode:NO];
    [TDAdsSDK setTestMode:NO];

    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:[MainViewController new]];
    self.window.rootViewController = nav;
    [self.window makeKeyAndVisible];
    return YES;
}
@end
