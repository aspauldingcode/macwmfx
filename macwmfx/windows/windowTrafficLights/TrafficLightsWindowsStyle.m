//
//  TrafficLightsWindowsStyle.m
//  macwmfx
//
//  Created by Alex "aspauldingcode" on 11/13/24.
//  Copyright (c) 2024 Alex "aspauldingcode". All rights reserved.
//
#import <Cocoa/Cocoa.h>
#import "../../headers/macwmfx_globals.h"

ZKSwizzleInterface(BS_NSWindow_Traffic_Windows, NSWindow, NSWindow)

@implementation BS_NSWindow_Traffic_Windows

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
    // Only proceed if traffic lights are enabled, style is "windows", and position is "top-left"
    if (!button || !gTrafficLightsConfig.enabled || 
        ![gTrafficLightsConfig.style isEqualToString:@"windows"] ||
        ![gTrafficLightsConfig.position isEqualToString:@"top-left"]) {
        return button;
    }
    
    @try {
        NSView *titleBar = [button superview];
        if (titleBar && ![titleBar.subviews containsObject:button]) {
            [titleBar addSubview:button];
        }
        
        // Use default spacing of 10 (could be made configurable in the future)
        const CGFloat spacing = 10;
        
        // Reorder the buttons to match Windows style (minimize, maximize, close)
        if (b == NSWindowCloseButton) {
            // Move close button to the rightmost position
            [button setFrameOrigin:NSMakePoint(titleBar.frame.size.width - button.frame.size.width - spacing, button.frame.origin.y)];
        } else if (b == NSWindowZoomButton) {
            // Move maximize (zoom) button to the left of close button
            NSButton *closeButton = [self standardWindowButton:NSWindowCloseButton];
            if (closeButton) {
                CGFloat zoomX = closeButton.frame.origin.x - button.frame.size.width - spacing;
                [button setFrameOrigin:NSMakePoint(zoomX, button.frame.origin.y)];
            } else {
                // Hide zoom button if close button is not available
                [button setHidden:YES];
            }
        } else if (b == NSWindowMiniaturizeButton) {
            // Move minimize button to the left of maximize button
            NSButton *zoomButton = [self standardWindowButton:NSWindowZoomButton];
            if (zoomButton) {
                CGFloat minimizeX = zoomButton.frame.origin.x - button.frame.size.width - spacing;
                [button setFrameOrigin:NSMakePoint(minimizeX, button.frame.origin.y)];
            } else {
                // Hide minimize button if zoom button is not available
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