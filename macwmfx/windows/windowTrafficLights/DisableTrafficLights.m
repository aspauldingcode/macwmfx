//
//  DisableTrafficLights.m
// macwmfx
//
//  Created by Alex "aspauldingcode" on 11/13/24.
//  Copyright (c) 2024 Alex "aspauldingcode". All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "../../headers/macwmfx_globals.h"

ZKSwizzleInterface(BS_NSWindow_TrafficLights, NSWindow, NSWindow)

@implementation BS_NSWindow_TrafficLights

- (void)makeKeyAndOrderFront:(id)sender {
    ZKOrig(void, sender);
    
    // Skip if this is not a regular window
    if (!(self.styleMask & NSWindowStyleMaskTitled)) return;
    
    [self updateTrafficLightVisibility];
    
    // Subscribe to config changes
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self
                                                      selector:@selector(handleConfigChange:)
                                                          name:@"com.macwmfx.configChanged"
                                                        object:nil];
}

- (void)dealloc {
    [[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
    ZKOrig(void);
}

- (void)handleConfigChange:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateTrafficLightVisibility];
    });
}

- (void)updateTrafficLightVisibility {
    @try {
        // Skip if this is not a regular window
        if (!(self.styleMask & NSWindowStyleMaskTitled)) return;
        
        // Get the traffic light buttons
        NSButton *closeButton = [self standardWindowButton:NSWindowCloseButton];
        NSButton *minimizeButton = [self standardWindowButton:NSWindowMiniaturizeButton];
        NSButton *zoomButton = [self standardWindowButton:NSWindowZoomButton];
        
        if (!closeButton || !minimizeButton || !zoomButton) {
            NSLog(@"[macwmfx] Traffic light buttons not found for visibility");
            return;
        }
        
        // Update visibility based on config
        BOOL shouldHide = !gTrafficLightsConfig.enabled;
        NSLog(@"[macwmfx] Setting traffic lights visibility: %@", shouldHide ? @"hidden" : @"visible");
        
        for (NSButton *button in @[closeButton, minimizeButton, zoomButton]) {
            [button setHidden:shouldHide];
        }
        
    } @catch (NSException *e) {
        NSLog(@"[macwmfx] Error updating traffic light visibility: %@", e);
    }
}

@end