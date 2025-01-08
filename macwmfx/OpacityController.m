//
//  OpacityController.m
//  macwmfx
//
//  Created by Alex "aspauldingcode" on 11/13/24.
//  Copyright (c) 2024 Alex "aspauldingcode". All rights reserved.
//

#import "macwmfx_globals.h"

@interface OpacityController : NSObject
@end

@implementation OpacityController

+ (void)load {
    // Nothing needed here since we just want the swizzle
}

@end

ZKSwizzleInterface(BS_NSWindow_Opacity, NSWindow, NSWindow)

@implementation BS_NSWindow_Opacity

- (void)makeKeyAndOrderFront:(id)sender {
    ZKOrig(void, sender);
    
    // Skip if this is not a regular window (e.g., menu, tooltip, etc.)
    if (!(self.styleMask & NSWindowStyleMaskTitled)) return;
    
    NSWindow *window = (NSWindow *)self;
    CGFloat opacity = MAX(0.1, MIN(1.0, gTransparency));
    
    // Find all subviews except the red background view
    NSView *contentView = window.contentView;
    CGColorRef redColor = [[NSColor redColor] CGColor];
    for (NSView *subview in contentView.subviews) {
        // Skip the red background view (which is positioned at NSWindowBelow)
        if (CGColorEqualToColor(subview.layer.backgroundColor, redColor)) {
            continue;
        }
        subview.alphaValue = opacity;
    }
    
    // Keep window background clear to not interfere with the red background
    window.backgroundColor = [NSColor clearColor];
    window.opaque = NO;
}

@end