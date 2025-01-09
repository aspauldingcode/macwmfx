//
//  TrafficLightsShape.m
//  macwmfx
//
//  Created by Alex "aspauldingcode" on 01/09/25.
//  Copyright (c) 2025 Alex "aspauldingcode". All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "../../headers/macwmfx_globals.h"

ZKSwizzleInterface(BS_NSWindow_TrafficLightsShape, NSWindow, NSWindow)

@implementation BS_NSWindow_TrafficLightsShape

- (void)makeKeyAndOrderFront:(id)sender {
    ZKOrig(void, sender);
    
    // Skip if this is not a regular window
    if (!(self.styleMask & NSWindowStyleMaskTitled)) return;
    
    [self updateTrafficLightShape];
    
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
        [self updateTrafficLightShape];
    });
}

- (void)updateTrafficLightShape {
    @try {
        // Skip if this is not a regular window
        if (!(self.styleMask & NSWindowStyleMaskTitled)) return;
        
        // Get the traffic light buttons
        NSButton *closeButton = [self standardWindowButton:NSWindowCloseButton];
        NSButton *minimizeButton = [self standardWindowButton:NSWindowMiniaturizeButton];
        NSButton *zoomButton = [self standardWindowButton:NSWindowZoomButton];
        
        if (!closeButton || !minimizeButton || !zoomButton) {
            NSLog(@"[macwmfx] Traffic light buttons not found for shape");
            return;
        }
        
        // Reset shape to default first
        for (NSButton *button in @[closeButton, minimizeButton, zoomButton]) {
            button.wantsLayer = YES;
            button.layer.cornerRadius = 0;
            button.layer.masksToBounds = NO;
        }
        
        // Only apply shape if traffic lights are enabled and we have a shape specified
        if (gTrafficLightsConfig.enabled && gTrafficLightsConfig.shape) {
            CGFloat cornerRadius = 0;
            
            if ([gTrafficLightsConfig.shape isEqualToString:@"circle"]) {
                // For a circle, corner radius should be half the width/height
                cornerRadius = gTrafficLightsConfig.size > 0 ? 
                             gTrafficLightsConfig.size / 2.0 : 6.0; // Default size is 12, so radius is 6
            } else if ([gTrafficLightsConfig.shape isEqualToString:@"square"]) {
                // For square, keep corner radius at 0
                cornerRadius = 0;
            }
            // Add other shapes here as needed
            
            for (NSButton *button in @[closeButton, minimizeButton, zoomButton]) {
                button.layer.cornerRadius = cornerRadius;
                button.layer.masksToBounds = YES;
            }
            NSLog(@"[macwmfx] Applied %@ shape to traffic lights", gTrafficLightsConfig.shape);
        }
        
    } @catch (NSException *e) {
        NSLog(@"[macwmfx] Error updating traffic light shape: %@", e);
    }
}

@end
