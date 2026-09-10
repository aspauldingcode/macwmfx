#import <AppKit/AppKit.h>
#import <Foundation/Foundation.h>

/**
 * macwmfx Core Interfaces
 */

@interface ConfigParser : NSObject
@property(nonatomic, strong, readonly) NSDictionary *rawConfig;
+ (instancetype)sharedInstance;
- (void)loadConfig;
@end

@interface macwmfxRuleEngine : NSObject

/**
 * Resolves the final appearance configuration for a given window.
 * Matches global rules and per-app/per-window rules.
 */
+ (NSDictionary *)resolveAppearanceForWindow:(NSWindow *)window;

@end
