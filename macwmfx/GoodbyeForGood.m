#import <Cocoa/Cocoa.h>
#import "ZKSwizzle.h"

@interface GoodbyeForGood : NSObject
@end

@implementation GoodbyeForGood

+ (void)load {
    // Register for window closing notifications
    [[NSNotificationCenter defaultCenter] addObserver:[self class]
                                           selector:@selector(windowWillClose:)
                                               name:NSWindowWillCloseNotification
                                             object:nil];
}

+ (void)windowWillClose:(NSNotification *)notification {
    // Run on next run loop to avoid race conditions
    dispatch_async(dispatch_get_main_queue(), ^{
        @try {
            // Check if this was the last window
            NSArray *windows = [NSApp windows];
            NSUInteger visibleWindows = 0;
            
            // Get the bundle ID once
            NSString *bundleID = [NSBundle mainBundle].bundleIdentifier;
            
            // Skip certain apps that shouldn't be terminated
            if ([bundleID isEqualToString:@"com.apple.dock"] ||
                [bundleID isEqualToString:@"com.apple.systemuiserver"] ||
                [bundleID isEqualToString:@"com.apple.WindowManager"] ||
                [bundleID isEqualToString:@"com.apple.mail"] ||
                [bundleID isEqualToString:@"com.apple.iCal"] ||
                [bundleID isEqualToString:@"org.m0k.transmission"] ||
                [bundleID isEqualToString:@"com.viscosityvpn.Viscosity"] ||
                [bundleID isEqualToString:@"com.apple.ScreenSharing"] ||
                [bundleID isEqualToString:@"org.mozilla.firefox"] ||
                [bundleID isEqualToString:@"com.apple.launchpad.launcher"]) {
                return;
            }
            
            // Safely check windows
            if (windows) {
                for (NSWindow *window in windows) {
                    // Skip if window is nil
                    if (!window) continue;
                    
                    @try {
                        // Skip if it's not a regular window
                        if (!(window.styleMask & NSWindowStyleMaskTitled)) {
                            continue;
                        }
                        
                        // Skip system windows, panels, sheets, etc
                        if (window.level != NSNormalWindowLevel) {
                            continue;
                        }
                        
                        // Skip if it's a special window class (like panels or sheets)
                        NSString *className = NSStringFromClass([window class]);
                        if (!className || 
                            [className containsString:@"Panel"] || 
                            [className containsString:@"Sheet"] ||
                            [className containsString:@"Popover"] ||
                            [className containsString:@"HUD"] ||
                            [className containsString:@"Helper"]) {
                            continue;
                        }
                        
                        if ([window isVisible]) {
                            visibleWindows++;
                        }
                    }
                    @catch (NSException *e) {
                        NSLog(@"GoodbyeForGood: Exception while processing window: %@", e);
                        continue;
                    }
                }
            }
            
            static NSMutableDictionary *hasHadWindows = nil;
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^{
                hasHadWindows = [NSMutableDictionary new];
            });
            
            // If we see windows, mark that this app has had windows
            if (visibleWindows > 0) {
                hasHadWindows[bundleID] = @YES;
            }
            
            // Only terminate if:
            // 1. There are no visible windows now
            // 2. The app has had windows before (hasHadWindows is YES)
            // 3. The app is active (not in background)
            if (visibleWindows == 0 && [hasHadWindows[bundleID] boolValue] && [NSApp isActive]) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    @try {
                        [NSApp terminate:nil];
                    }
                    @catch (NSException *e) {
                        NSLog(@"GoodbyeForGood: Exception while terminating app: %@", e);
                    }
                });
            }
        }
        @catch (NSException *e) {
            NSLog(@"GoodbyeForGood: Exception in windowWillClose: %@", e);
        }
    });
}

@end
