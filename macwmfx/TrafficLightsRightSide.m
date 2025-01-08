//
//  TrafficLightsRightSide.m
// macwmfx
//
//  Created by Alex "aspauldingcode" on 11/13/24.
//  Copyright (c) 2024 Alex "aspauldingcode". All rights reserved.
//

#import "macwmfx_globals.h"

ZKSwizzleInterface(BS_NSWindow_Traffic, NSWindow, NSWindow)

@implementation BS_NSWindow_Traffic

- (nullable NSButton *)standardWindowButton:(NSWindowButton)b {
    NSButton *button = ZKOrig(NSButton*, b);
    if (button) {
        @try {
            // Move traffic lights to the right side
            NSView *titleBar = [button superview];
            if (titleBar && ![titleBar.subviews containsObject:button]) {
                [titleBar addSubview:button];
            }
            
            // Adjust the ordering: zoom, minimize, close
            if (b == NSWindowCloseButton) {
                // Move close button to the rightmost position
                [button setFrameOrigin:NSMakePoint(titleBar.frame.size.width - button.frame.size.width - 10, button.frame.origin.y)];
            } else if (b == NSWindowZoomButton) {
                // Move zoom button to the left of close button
                NSButton *closeButton = [self standardWindowButton:NSWindowCloseButton];
                if (closeButton) {
                    CGFloat zoomX = closeButton.frame.origin.x - button.frame.size.width - 10;
                    [button setFrameOrigin:NSMakePoint(zoomX, button.frame.origin.y)];
                } else {
                    // Hide zoom button if close button is not available
                    [button setHidden:YES];
                }
            } else if (b == NSWindowMiniaturizeButton) {
                // Move minimize button to the left of zoom button
                NSButton *zoomButton = [self standardWindowButton:NSWindowZoomButton];
                if (zoomButton) {
                    CGFloat minimizeX = zoomButton.frame.origin.x - button.frame.size.width - 10;
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
    return button;
}

@end