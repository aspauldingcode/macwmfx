//
//  DisableTrafficLights.m
// macwmfx
//
//  Created by Alex "aspauldingcode" on 11/13/24.
//  Copyright (c) 2024 Alex "aspauldingcode". All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "../../headers/macwmfx_globals.h"

ZKSwizzleInterface(BS_NSWindow_Traffic, NSWindow, NSWindow)

@implementation BS_NSWindow_Traffic

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
    if (!gTrafficLightsConfig.enabled && button) {
        [button setHidden:YES];
    }
    return button;
}

@end