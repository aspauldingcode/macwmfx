//
//  TrafficLightsStyle.m
//  macwmfx
//
//  Created by Alex "aspauldingcode" on 01/09/25.
//  Copyright (c) 2025 Alex "aspauldingcode". All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "../../headers/macwmfx_globals.h"

ZKSwizzleInterface(BS_NSWindow_TrafficLightsStyle, NSWindow, NSWindow)

@implementation BS_NSWindow_TrafficLightsStyle

- (void)makeKeyAndOrderFront:(id)sender {
    ZKOrig(void, sender);
    
    // Skip if this is not a regular window
    if (!(self.styleMask & NSWindowStyleMaskTitled)) return;
    
    [self updateTrafficLightStyle];
    
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
        [self updateTrafficLightStyle];
    });
}

- (void)updateTrafficLightStyle {
    @try {
        // Skip if this is not a regular window
        if (!(self.styleMask & NSWindowStyleMaskTitled)) return;
        
        // Get the traffic light buttons
        NSButton *closeButton = [self standardWindowButton:NSWindowCloseButton];
        NSButton *minimizeButton = [self standardWindowButton:NSWindowMiniaturizeButton];
        NSButton *zoomButton = [self standardWindowButton:NSWindowZoomButton];
        
        if (!closeButton || !minimizeButton || !zoomButton) {
            NSLog(@"[macwmfx] Traffic light buttons not found for style");
            return;
        }
        
        // Get the container view
        NSView *container = closeButton.superview;
        if (!container) {
            NSLog(@"[macwmfx] Traffic light container not found for style");
            return;
        }
        
        // Only proceed if traffic lights are enabled
        if (!gTrafficLightsConfig.enabled) return;
        
        // Reset to default style first
        for (NSButton *button in @[closeButton, minimizeButton, zoomButton]) {
            button.wantsLayer = YES;
            [button setButtonType:NSButtonTypeMomentaryLight];
            [button setBordered:NO];
            button.layer.borderWidth = 0;
            button.layer.borderColor = nil;
        }
        
        // Apply custom colors if enabled
        if (gTrafficLightsConfig.customColor.enabled) {
            ConfigParser *parser = [ConfigParser sharedInstance];
            BOOL isActive = self.isKeyWindow;
            TrafficLightsColorState *colorState = isActive ? 
                &gTrafficLightsConfig.customColor.active : 
                &gTrafficLightsConfig.customColor.inactive;
            
            if (colorState->stop) {
                closeButton.layer.backgroundColor = [parser colorFromHexString:colorState->stop].CGColor;
            }
            if (colorState->yield) {
                minimizeButton.layer.backgroundColor = [parser colorFromHexString:colorState->yield].CGColor;
            }
            if (colorState->go) {
                zoomButton.layer.backgroundColor = [parser colorFromHexString:colorState->go].CGColor;
            }
            
            NSLog(@"[macwmfx] Applied custom traffic light colors for %@ state", isActive ? @"active" : @"inactive");
        }
        
        // Apply style based on configuration
        if ([gTrafficLightsConfig.style isEqualToString:@"windows"]) {
            // Windows-style traffic lights
            for (NSButton *button in @[closeButton, minimizeButton, zoomButton]) {
                button.layer.borderWidth = 1.0;
                button.layer.borderColor = [NSColor grayColor].CGColor;
                [button setBordered:YES];
                [button setBezelStyle:NSBezelStyleFlexiblePush];
            }
            NSLog(@"[macwmfx] Applied Windows style to traffic lights");
        } else if ([gTrafficLightsConfig.style isEqualToString:@"flat"]) {
            // Flat style traffic lights
            for (NSButton *button in @[closeButton, minimizeButton, zoomButton]) {
                button.layer.borderWidth = 0;
                [button setBordered:NO];
                [button setBezelStyle:NSBezelStyleTexturedSquare];
            }
            NSLog(@"[macwmfx] Applied flat style to traffic lights");
        } else {
            // Default macOS style
            NSLog(@"[macwmfx] Applied macOS style to traffic lights");
        }
        
        // Force redraw
        [container setNeedsDisplay:YES];
        [self display];
        
    } @catch (NSException *e) {
        NSLog(@"[macwmfx] Error updating traffic light style: %@", e);
    }
}

- (void)becomeKeyWindow {
    ZKOrig(void);
    [self updateTrafficLightStyle];
}

- (void)resignKeyWindow {
    ZKOrig(void);
    [self updateTrafficLightStyle];
}

@end
