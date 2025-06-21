//
//  disableTrafficLights.m
//  macwmfx
//
//  Created by Alex "aspauldingcode" on 01/10/25.
//  Copyright (c) 2025 Alex "aspauldingcode". All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "../../headers/macwmfx_globals.h"

ZKSwizzleInterface(BS_NSWindow_DisableTrafficLights, NSWindow, NSWindow)

@implementation BS_NSWindow_DisableTrafficLights

+ (void)initialize {
    if (self == [BS_NSWindow_DisableTrafficLights class]) {
        // Register for config changes
        [[NSDistributedNotificationCenter defaultCenter] addObserver:self
                                                          selector:@selector(handleConfigChange:)
                                                              name:@"com.macwmfx.configChanged"
                                                            object:nil
                                                suspensionBehavior:NSNotificationSuspensionBehaviorDeliverImmediately];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                               selector:@selector(handleConfigChange:)
                                                   name:@"com.macwmfx.configChanged"
                                                 object:nil];
        
        NSLog(@"[macwmfx] Traffic lights visibility controller initialized");
    }
}

+ (void)handleConfigChange:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateAllWindowTrafficLights];
    });
}

+ (void)updateAllWindowTrafficLights {
    NSLog(@"[macwmfx] Updating all traffic lights visibility. Enabled=%d", gTrafficLightsConfig.enabled);
    
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