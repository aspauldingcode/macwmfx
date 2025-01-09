//
//  ForceCustomTitle.m
//  macwmfx
//
//  Created by Alex "aspauldingcode" on 11/13/24.
//  Copyright (c) 2024 Alex "aspauldingcode". All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "../../headers/macwmfx_globals.h"

ZKSwizzleInterface(BS_NSWindow_CustomTitle, NSWindow, NSWindow)

@implementation BS_NSWindow_CustomTitle

- (void)setTitle:(NSString *)title {
    // Skip if this is not a regular window (e.g., menu, tooltip, etc.)
    if (!(self.styleMask & NSWindowStyleMaskTitled)) {
        ZKOrig(void, title);
        return;
    }
    
    // Apply custom title if enabled and available
    if (gCustomTitleConfig.enabled && gCustomTitleConfig.title && gCustomTitleConfig.title[0] != '\0') {
        [(NSWindow *)self setTitle:@(gCustomTitleConfig.title)];
    } else {
        ZKOrig(void, title);
    }
}

- (void)setTitleWithRepresentedFilename:(NSString *)filename {
    // Skip if this is not a regular window (e.g., menu, tooltip, etc.)
    if (!(self.styleMask & NSWindowStyleMaskTitled)) {
        ZKOrig(void, filename);
        return;
    }
    
    // Apply custom title if enabled and available
    if (gCustomTitleConfig.enabled && gCustomTitleConfig.title && gCustomTitleConfig.title[0] != '\0') {
        ZKOrig(void, @(gCustomTitleConfig.title));
    } else {
        ZKOrig(void, filename);
    }
}

@end