// #import "../../headers/macwmfx_globals.h"
// #import "../../headers/ZKSwizzle.h"
// #import <QuartzCore/QuartzCore.h>
// #import <AppKit/AppKit.h>

// // Swizzle NSWindow to enforce custom corner radius
// ZKSwizzleInterface(AS_NSWindow_CornerRadius, NSWindow, NSWindow)
// @implementation AS_NSWindow_CornerRadius

// - (void)setFrame:(NSRect)frameRect display:(BOOL)flag {
//     ZKOrig(void, frameRect, flag);
//     [self updateCornerRadius];
// }

// - (void)setStyleMask:(NSWindowStyleMask)styleMask {
//     ZKOrig(void, styleMask);
//     [self updateCornerRadius];
// }

// - (void)updateCornerRadius {
//     // Skip if window is in fullscreen mode
//     if (self.styleMask & NSWindowStyleMaskFullScreen) {
//         return;
//     }
    
//     // Only modify windows that are titled (application windows)
//     if (!(self.styleMask & NSWindowStyleMaskTitled)) {
//         return;
//     }
    
//     // Get the frame view (contentView's superview)
//     NSView *frameView = [self.contentView superview];
//     if (!frameView) return;
    
//     // Enable layer backing
//     frameView.wantsLayer = YES;
//     frameView.layer.masksToBounds = YES;
    
//     // Apply corner radius based on the config
//     if (gOutlineConfig.enabled) {
//         frameView.layer.cornerRadius = gOutlineConfig.cornerRadius;
//     } else {
//         frameView.layer.cornerRadius = 0; // Reset to default
//     }
// }

// @end

// // Swizzle the titlebar decoration view to prevent rounded corners
// ZKSwizzleInterface(AS_TitlebarDecorationView, _NSTitlebarDecorationView, NSView)
// @implementation AS_TitlebarDecorationView

// - (void)viewDidMoveToWindow {
//     ZKOrig(void);
//     // Only hide decoration for windows that are titled (application windows) and not in fullscreen
//     if ((self.window.styleMask & NSWindowStyleMaskTitled) &&
//         !(self.window.styleMask & NSWindowStyleMaskFullScreen)) {
//         self.hidden = gOutlineConfig.enabled;  // Hide the decoration view when outline is enabled
//     }
// }

// - (void)drawRect:(NSRect)dirtyRect {
//     // Only prevent drawing for titled windows when outline is enabled and not in fullscreen
//     if ((self.window.styleMask & NSWindowStyleMaskTitled) &&
//         !(self.window.styleMask & NSWindowStyleMaskFullScreen) &&
//         gOutlineConfig.enabled) {
//         return;  // No-op to prevent any drawing
//     }
//     ZKOrig(void, dirtyRect);
// }

// @end

// // Define a class to manage window outline updates
// @interface WindowOutlineManager : NSObject
// + (void)updateBorderForWindow:(NSWindow *)window;
// + (void)updateCornerRadiusForWindow:(NSWindow *)window;
// + (void)handleConfigChange:(NSNotification *)notification;
// @end

// @implementation WindowOutlineManager

// + (void)updateBorderForWindow:(NSWindow *)window {
//     // Only process windows that are titled and at normal window level.
//     if (!(window.styleMask & NSWindowStyleMaskTitled) ||
//         (window.level != NSNormalWindowLevel))
//         return;
    
//     NSView *frameView = [window.contentView superview];
//     if (!frameView) return;
    
//     // Force window update
//     [(id)window invalidateShadow];
//     [window.contentView setNeedsDisplay:YES];
//     [window displayIfNeeded];
    
//     // Update the titlebar decoration view if available.
//     NSView *titlebarView = [window standardWindowButton:NSWindowCloseButton].superview.superview;
//     if ([titlebarView isKindOfClass:NSClassFromString(@"_NSTitlebarDecorationView")]) {
//         if (window.styleMask & NSWindowStyleMaskFullScreen) {
//             // In fullscreen, revert to system default by showing the decoration.
//             titlebarView.hidden = NO;
//         } else {
//             titlebarView.hidden = gOutlineConfig.enabled;
//         }
//         [titlebarView setNeedsDisplay:YES];
//     }
// }

// + (void)updateCornerRadiusForWindow:(NSWindow *)window {
//     // Only process windows that are titled and at normal window level.
//     if (!(window.styleMask & NSWindowStyleMaskTitled) ||
//         (window.level != NSNormalWindowLevel))
//         return;
    
//     NSView *frameView = [window.contentView superview];
//     if (!frameView) return;
    
//     frameView.wantsLayer = YES;
//     [CATransaction begin];
//     [CATransaction setDisableActions:YES];
    
//     if (window.styleMask & NSWindowStyleMaskFullScreen) {
//         // In fullscreen, always reset to the default corner radius.
//         frameView.layer.cornerRadius = 0;
//     } else {
//         // For non-fullscreen windows, apply the corner radius from the config if outline is enabled.
//         if (gOutlineConfig.enabled) {
//             frameView.layer.cornerRadius = gOutlineConfig.cornerRadius;
//         } else {
//             // Reset to default corner radius when outline is disabled.
//             frameView.layer.cornerRadius = 0; // or macOS default value
//         }
//     }
    
//     [CATransaction commit];
// }

// + (void)handleConfigChange:(NSNotification *)notification {
//     dispatch_async(dispatch_get_main_queue(), ^{
//         // Iterate through all windows and update the border and corner radius accordingly.
//         for (NSWindow *window in [NSApp windows]) {
//             if (![window isKindOfClass:[NSWindow class]]) continue;
//             [self updateBorderForWindow:window];
//             [self updateCornerRadiusForWindow:window];
//         }
//     });
// }

// @end

// // Initialize the WindowOutlineManager when the module loads
// __attribute__((constructor))
// static void initializeWindowOutlineManager() {
//     // Register for config change notifications
//     [[NSDistributedNotificationCenter defaultCenter] addObserver:[WindowOutlineManager class]
//                                                       selector:@selector(handleConfigChange:)
//                                                           name:@"com.macwmfx.configChanged"
//                                                         object:nil
//                                             suspensionBehavior:NSNotificationSuspensionBehaviorDeliverImmediately];
    
//     [[NSNotificationCenter defaultCenter] addObserver:[WindowOutlineManager class]
//                                              selector:@selector(handleConfigChange:)
//                                                  name:@"com.macwmfx.configChanged"
//                                                object:nil];
    
//     NSLog(@"[macwmfx] Window outline manager initialized");
// }