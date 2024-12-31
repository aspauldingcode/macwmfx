// #import "macwmfx_globals.h"

// // Apps that should never be terminated
// static NSSet *excludedBundleIDs;

// ZKSwizzleInterface(BS_NSWindow_GoodbyeForGood, NSObject, NSObject)
// @implementation BS_NSWindow_GoodbyeForGood

// + (void)initialize {
//     excludedBundleIDs = [NSSet setWithArray:@[
//         @"com.apple.dock",
//         @"com.apple.systemuiserver",
//         @"com.apple.WindowManager",
//         @"com.apple.mail",
//         @"com.apple.iCal",
//         @"org.m0k.transmission",
//         @"com.viscosityvpn.Viscosity",
//         @"com.apple.ScreenSharing",
//         @"org.mozilla.firefox",
//         @"com.apple.launchpad.launcher"
//     ]];
    
//     [[NSNotificationCenter defaultCenter] addObserver:self
//                                            selector:@selector(windowWillClose:)
//                                                name:NSWindowWillCloseNotification
//                                              object:nil];
// }

// + (void)windowWillClose:(NSNotification *)notification {
//     dispatch_async(dispatch_get_main_queue(), ^{
//         NSString *bundleID = [NSBundle mainBundle].bundleIdentifier;
//         if ([excludedBundleIDs containsObject:bundleID]) return;
        
//         NSUInteger visibleWindows = 0;
//         for (NSWindow *window in [NSApp windows]) {
//             if (!window || !(window.styleMask & NSWindowStyleMaskTitled)) continue;
//             if (window.level != NSNormalWindowLevel) continue;
            
//             NSString *className = NSStringFromClass([window class]);
//             if ([className containsString:@"Panel"] || 
//                 [className containsString:@"Sheet"] ||
//                 [className containsString:@"Popover"] ||
//                 [className containsString:@"HUD"] ||
//                 [className containsString:@"Helper"]) continue;
            
//             if ([window isVisible]) visibleWindows++;
//         }
        
//         static NSMutableSet *appsWithWindows;
//         static dispatch_once_t onceToken;
//         dispatch_once(&onceToken, ^{
//             appsWithWindows = [NSMutableSet new];
//         });
        
//         if (visibleWindows > 0) {
//             [appsWithWindows addObject:bundleID];
//         } else if ([appsWithWindows containsObject:bundleID] && [NSApp isActive]) {
//             dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), 
//                          dispatch_get_main_queue(), ^{
//                 [NSApp terminate:nil];
//             });
//         }
//     });
// }

// @end
