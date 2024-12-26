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
    dispatch_async(dispatch_get_main_queue(), ^{
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
            [bundleID isEqualToString:@"org.mozilla.firefox"]) {
            return;
        }
        
        for (NSWindow *window in windows) {
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
            if ([className containsString:@"Panel"] || 
                [className containsString:@"Sheet"] ||
                [className containsString:@"Popover"] ||
                [className containsString:@"HUD"] ||
                [className containsString:@"Helper"]) {
                continue;
            }
            
            // Special handling for Finder
            if ([bundleID isEqualToString:@"com.apple.finder"]) {
                if (![className containsString:@"BrowserWindow"]) {
                    continue;
                }
            }
            
            if ([window isVisible]) {
                visibleWindows++;
            }
        }
        
        // If no more visible windows, terminate the app
        if (visibleWindows == 0 && [NSApp isActive]) {
            // Add a small delay to prevent race conditions
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [NSApp terminate:nil];
            });
        }
    });
}

@end
