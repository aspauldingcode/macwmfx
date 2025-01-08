//
//  WindowBordersInline.m
//  macwmfx
//
//  Created by Alex "aspauldingcode" on 11/13/24.
//  Copyright (c) 2024 Alex "aspauldingcode". All rights reserved.
//

#import "macwmfx_globals.h"
#import <QuartzCore/QuartzCore.h>

@interface NSWindow (Private)
- (BOOL)_getCornerRadius:(CGFloat *)radius;
@end

ZKSwizzleInterface(BS_NSWindow_BordersInline, NSWindow, NSWindow)

@implementation BS_NSWindow_BordersInline

   - (void)updateBorderStyle {
        // Skip if borders are disabled or window is in fullscreen
        if (!gOutlineEnabled || ![gOutlineType isEqualToString:@"inline"] || 
            (self.styleMask & NSWindowStyleMaskFullScreen)) {
            // Clear existing borders if disabled
            NSView *frameView = [self.contentView superview];
            if (frameView) {
                frameView.wantsLayer = YES;
                frameView.layer.borderWidth = 0;
                frameView.layer.cornerRadius = 0;  // Reset corner radius when borders are disabled
                frameView.layer.borderColor = nil;
            }
            return;
        }
        
        // Skip if this is not a regular window (e.g., menu, tooltip, etc.)
        if (!(self.styleMask & NSWindowStyleMaskTitled)) return;
        
        NSView *frameView = [self.contentView superview];
        if (!frameView) return;
        
        // Get the window's corner radius from its mask
        CGFloat windowCornerRadius = 0;
        if ([self respondsToSelector:@selector(_getCornerRadius:)]) {
            [self _getCornerRadius:&windowCornerRadius];
        }
        
        [CATransaction begin];
        [CATransaction setDisableActions:YES];  // Disable animations
        
        frameView.wantsLayer = YES;
        frameView.layer.borderWidth = gOutlineWidth;
        frameView.layer.cornerRadius = gOutlineCornerRadius;
        frameView.layer.borderColor = self.isKeyWindow ? gOutlineActiveColor.CGColor : gOutlineInactiveColor.CGColor;
        
        [CATransaction commit];
        
        // Force redraw
        [frameView setNeedsDisplay:YES];
        [self.contentView setNeedsDisplay:YES];
        [self display];
    }

- (void)makeKeyAndOrderFront:(id)sender {
    ZKOrig(void, sender);
    [self updateBorderStyle];
}

- (void)becomeKeyWindow {
    ZKOrig(void);
    [self updateBorderStyle];
}

- (void)resignKeyWindow {
    ZKOrig(void);
    [self updateBorderStyle];
}

@end