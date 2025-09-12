//
//  DisableWindowShadow.m
//  macwmfx
//
//  Created by Alex "aspauldingcode" on 11/13/24.
//  Copyright (c) 2024 Alex "aspauldingcode". All rights reserved.
//

#import <AppKit/AppKit.h>
#import "../../../../shared/headers/macwmfx_globals.h"
#import "../../../../shared/macwmfx_logging.h"

ZKSwizzleInterface(BS_NSWindow_Shadow, NSWindow, NSWindow)

@implementation BS_NSWindow_Shadow

+ (void)load {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(configChanged:)
                                                 name:@"com.aspauldingcode.macwmfx.configChanged"
                                               object:nil];
    MACWMFX_LOG_INFO(macwmfx_log_shadow, "Shadow controller initialized - listening for config changes");
}

+ (void)updateAllWindowShadows {
    MACWMFX_LOG_INFO(macwmfx_log_shadow, "Updating all window shadows. Shadow enabled=%d", gShadowConfig.enabled);

    dispatch_async(dispatch_get_main_queue(), ^{
        for (NSWindow *window in [NSApp windows]) {
            if (![window isKindOfClass:[NSWindow class]]) continue;
            if (!(window.styleMask & NSWindowStyleMaskTitled)) continue;

            // Force update the shadow state
            [window setHasShadow:NO];  // Reset state
            [window setHasShadow:gShadowConfig.enabled];  // Apply new state

            // Force window to update
            [window displayIfNeeded];

            MACWMFX_LOG_DEBUG(macwmfx_log_shadow, "Updated window shadow: %{public}@", window);
        }
    });
}

- (void)makeKeyAndOrderFront:(id)sender {
    ZKOrig(void, sender);

    if (!(self.styleMask & NSWindowStyleMaskTitled)) return;

    // Force update shadow state when window becomes key
    [(NSWindow *)self setHasShadow:NO];  // Reset state
    [(NSWindow *)self setHasShadow:gShadowConfig.enabled];  // Apply new state
    [(NSWindow *)self displayIfNeeded];
}

- (void)setHasShadow:(BOOL)hasShadow {
    if (!(self.styleMask & NSWindowStyleMaskTitled)) {
        ZKOrig(void, hasShadow);
        return;
    }

    // Always respect the global shadow config
    BOOL finalState = gShadowConfig.enabled ? hasShadow : NO;
    ZKOrig(void, finalState);
}

+ (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
}

+ (void)configChanged:(NSNotification *)notification {
    MACWMFX_LOG_INFO(macwmfx_log_shadow, "Config changed, updating all window shadows. Shadow enabled=%d", gShadowConfig.enabled);

    // Update all windows
    NSArray *windows = [NSApp windows];
    for (NSWindow *window in windows) {
        [window setHasShadow:gShadowConfig.enabled];
        MACWMFX_LOG_DEBUG(macwmfx_log_shadow, "Updated window shadow: %{public}@", window);
    }
}

@end
