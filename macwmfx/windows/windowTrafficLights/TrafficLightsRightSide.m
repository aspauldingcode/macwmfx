//
//  TrafficLightsRightSide.m
// macwmfx
//
//  Created by Alex "aspauldingcode" on 11/13/24.
//  Copyright (c) 2024 Alex "aspauldingcode". All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "../../headers/macwmfx_globals.h"

ZKSwizzleInterface(BS_NSWindow_Traffic_Right, NSWindow, NSWindow)

@implementation BS_NSWindow_Traffic_Right

- (nullable NSButton *)standardWindowButton:(NSWindowButton)b {
    // Skip if this is not a regular window (e.g., menu, tooltip, etc.)
    if (!(self.styleMask & NSWindowStyleMaskTitled)) {
        return ZKOrig(NSButton*, b);
    }
    
    // Only handle close, minimize, and zoom buttons
    if (b != NSWindowCloseButton && 
        b != NSWindowMiniaturizeButton && 
        b != NSWindowZoomButton) {
        return ZKOrig(NSButton*, b);
    }
    
    NSButton *button = ZKOrig(NSButton*, b);
    // Only proceed if traffic lights are enabled, position is "top-right", and style is "macOS"
    if (!button || !gTrafficLightsConfig.enabled || 
        ![gTrafficLightsConfig.position isEqualToString:@"top-right"] ||
        ![gTrafficLightsConfig.style isEqualToString:@"macOS"]) {
        return button;
    }
    
    @try {
        // Move traffic lights to the right side
        NSView *titleBar = [button superview];
        if (titleBar && ![titleBar.subviews containsObject:button]) {
            [titleBar addSubview:button];
        }
        
        // Use default spacing of 10 (could be made configurable in the future)
        const CGFloat spacing = 10;
        
        // Adjust the ordering: close, minimize, zoom (macOS style)
        if (b == NSWindowCloseButton) {
            // Move close button to the rightmost position
            [button setFrameOrigin:NSMakePoint(titleBar.frame.size.width - button.frame.size.width - spacing, button.frame.origin.y)];
        } else if (b == NSWindowMiniaturizeButton) {
            // Move minimize button to the left of close button
            NSButton *closeButton = [self standardWindowButton:NSWindowCloseButton];
            if (closeButton) {
                CGFloat minimizeX = closeButton.frame.origin.x - button.frame.size.width - spacing;
                [button setFrameOrigin:NSMakePoint(minimizeX, button.frame.origin.y)];
            } else {
                // Hide minimize button if close button is not available
                [button setHidden:YES];
            }
        } else if (b == NSWindowZoomButton) {
            // Move zoom button to the left of minimize button
            NSButton *minimizeButton = [self standardWindowButton:NSWindowMiniaturizeButton];
            if (minimizeButton) {
                CGFloat zoomX = minimizeButton.frame.origin.x - button.frame.size.width - spacing;
                [button setFrameOrigin:NSMakePoint(zoomX, button.frame.origin.y)];
            } else {
                // Hide zoom button if minimize button is not available
                [button setHidden:YES];
            }
        }
    } @catch (NSException *exception) {
        // Hide the button if any error occurs to prevent crashes
        [button setHidden:YES];
    }
    
    return button;
}

@end