//
//  disableTrafficLights.m
//  macwmfx
//
//  Created by Alex "aspauldingcode" on 01/10/25.
//  Copyright (c) 2025 Alex "aspauldingcode". All rights reserved.
//

#import <AppKit/AppKit.h>
#import "../../../../shared/headers/macwmfx_globals.h"
#import "../../../../shared/macwmfx_logging.h"

ZKSwizzleInterface(BS_NSWindow_DisableTrafficLights, NSWindow, NSWindow)

@implementation BS_NSWindow_DisableTrafficLights

+ (void)load {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(configChanged:)
                                                 name:@"com.aspauldingcode.macwmfx.configChanged"
                                               object:nil];
    MACWMFX_LOG_INFO(macwmfx_log_traffic_lights, "Traffic lights visibility controller initialized");
}

+ (void)handleConfigChange:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateAllWindowTrafficLights];
    });
}

+ (void)updateAllWindowTrafficLights {
    MACWMFX_LOG_INFO(macwmfx_log_traffic_lights, "Updating all traffic lights visibility. Enabled=%d", gTrafficLightsConfig.enabled);

    for (NSWindow *window in [NSApp windows]) {
        if (![window isKindOfClass:[NSWindow class]]) continue;
        if (!(window.styleMask & NSWindowStyleMaskTitled)) continue;

        [self updateTrafficLightsForWindow:window];
    }
}

+ (void)updateTrafficLightsForWindow:(NSWindow *)window {
    NSButton *closeButton = [window standardWindowButton:NSWindowCloseButton];
    NSButton *minimizeButton = [window standardWindowButton:NSWindowMiniaturizeButton];
    NSButton *zoomButton = [window standardWindowButton:NSWindowZoomButton];

    BOOL shouldHide = !gTrafficLightsConfig.enabled;

    for (NSButton *button in @[closeButton, minimizeButton, zoomButton]) {
        if (button) {
            [button setHidden:shouldHide];
        }
    }
}

- (void)makeKeyAndOrderFront:(id)sender {
    ZKOrig(void, sender);

    if (!(self.styleMask & NSWindowStyleMaskTitled)) return;

    [BS_NSWindow_DisableTrafficLights updateTrafficLightsForWindow:(NSWindow *)self];
}

- (void)orderFront:(id)sender {
    ZKOrig(void, sender);

    if (!(self.styleMask & NSWindowStyleMaskTitled)) return;

    [BS_NSWindow_DisableTrafficLights updateTrafficLightsForWindow:(NSWindow *)self];
}

+ (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
}

@end
