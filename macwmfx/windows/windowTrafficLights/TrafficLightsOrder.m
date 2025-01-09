//
//  TrafficLightsOrder.m
//  macwmfx
//
//  Created by Alex "aspauldingcode" on 01/09/25.
//  Copyright (c) 2025 Alex "aspauldingcode". All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "../../headers/macwmfx_globals.h"

ZKSwizzleInterface(BS_NSWindow_TrafficLightsOrder, NSWindow, NSWindow)

@implementation BS_NSWindow_TrafficLightsOrder

- (void)makeKeyAndOrderFront:(id)sender {
    ZKOrig(void, sender);
    
    // Skip if this is not a regular window
    if (!(self.styleMask & NSWindowStyleMaskTitled)) return;
    
    [self updateTrafficLightOrder];
    
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
        [self updateTrafficLightOrder];
    });
}

- (void)updateTrafficLightOrder {
    @try {
        // Skip if this is not a regular window
        if (!(self.styleMask & NSWindowStyleMaskTitled)) return;
        
        // Get the traffic light buttons
        NSButton *closeButton = [self standardWindowButton:NSWindowCloseButton];
        NSButton *minimizeButton = [self standardWindowButton:NSWindowMiniaturizeButton];
        NSButton *zoomButton = [self standardWindowButton:NSWindowZoomButton];
        
        if (!closeButton || !minimizeButton || !zoomButton) {
            NSLog(@"[macwmfx] Traffic light buttons not found for ordering");
            return;
        }
        
        // Get the container view
        NSView *container = closeButton.superview;
        if (!container) {
            NSLog(@"[macwmfx] Traffic light container not found for ordering");
            return;
        }
        
        // Only proceed if traffic lights are enabled and we have an order specified
        if (!gTrafficLightsConfig.enabled || !gTrafficLightsConfig.order) return;
        
        // Parse the order string
        NSArray *orderParts = [gTrafficLightsConfig.order componentsSeparatedByString:@"-"];
        if (orderParts.count != 3) {
            NSLog(@"[macwmfx] Invalid traffic light order format: %@", gTrafficLightsConfig.order);
            return;
        }
        
        // Create a mapping of buttons
        NSDictionary *buttonMap = @{
            @"stop": closeButton,
            @"yield": minimizeButton,
            @"go": zoomButton
        };
        
        // Calculate spacing based on button size
        CGFloat buttonSize = gTrafficLightsConfig.size > 0 ? gTrafficLightsConfig.size : 12.0;
        CGFloat spacing = 8.0;  // Default macOS spacing
        CGFloat xPos = 8.0;     // Starting position
        
        // Reorder buttons
        for (NSString *part in orderParts) {
            NSButton *button = buttonMap[part];
            if (button) {
                NSRect frame = button.frame;
                frame.origin.x = xPos;
                button.frame = frame;
                xPos += buttonSize + spacing;
            }
        }
        
        NSLog(@"[macwmfx] Applied traffic light order: %@", gTrafficLightsConfig.order);
        
        // Force redraw
        [container setNeedsDisplay:YES];
        [self display];
        
    } @catch (NSException *e) {
        NSLog(@"[macwmfx] Error updating traffic light order: %@", e);
    }
}

@end 