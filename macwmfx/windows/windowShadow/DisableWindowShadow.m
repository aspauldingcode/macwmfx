//
//  DisableWindowShadow.m
//  macwmfx
//
//  Created by Alex "aspauldingcode" on 11/13/24.
//  Copyright (c) 2024 Alex "aspauldingcode". All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "../../headers/macwmfx_globals.h"

ZKSwizzleInterface(BS_NSWindow_Shadow, NSWindow, NSWindow)

@implementation BS_NSWindow_Shadow

- (void)makeKeyAndOrderFront:(id)sender {
    ZKOrig(void, sender);
    
    // Skip if this is not a regular window (e.g., menu, tooltip, etc.)
    if (!(self.styleMask & NSWindowStyleMaskTitled)) return;
    
    if (gShadowConfig.enabled) {
        [(NSWindow *)self setHasShadow:NO];
    }
}

- (void)setHasShadow:(BOOL)hasShadow {
    // Skip if this is not a regular window (e.g., menu, tooltip, etc.)
    if (!(self.styleMask & NSWindowStyleMaskTitled)) {
        ZKOrig(void, hasShadow);
        return;
    }
    
    ZKOrig(void, gShadowConfig.enabled ? NO : hasShadow);
}

@end