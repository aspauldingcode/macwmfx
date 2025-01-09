//
//  OpacityController.m
//  macwmfx
//
//  Created by Alex "aspauldingcode" on 11/13/24.
//  Copyright (c) 2024 Alex "aspauldingcode". All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "../../headers/macwmfx_globals.h"

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
    
    // Skip if this is not a regular window
    if (!(self.styleMask & NSWindowStyleMaskTitled)) return;
    
    // Skip if window is in fullscreen
    if (self.styleMask & NSWindowStyleMaskFullScreen) {
        // Reset opacity and remove background when entering fullscreen
        [self resetWindowOpacity];
        return;
    }
    
    // Check if transparency is enabled and has a valid value
    if (gTransparencyConfig.enabled && gTransparencyConfig.value >= 0.0) {
        [self updateWindowOpacity];
    } else {
        [self resetWindowOpacity];
    }
}

- (void)resetWindowOpacity {
    NSView *contentView = self.contentView;
    if (!contentView) return;
    
    // Reset opacity for all subviews
    for (NSView *subview in [contentView.subviews copy]) {
        if (CGColorEqualToColor(subview.layer.backgroundColor, [[NSColor redColor] CGColor])) {
            [subview removeFromSuperview];
        } else {
            subview.alphaValue = 1.0;
        }
    }
    
    // Reset window properties
    self.backgroundColor = [NSColor windowBackgroundColor];
    self.opaque = YES;
}

- (void)updateWindowOpacity {
    NSView *contentView = self.contentView;
    if (!contentView) return;
    
    // Clamp opacity between 0.1 and 1.0 to prevent completely invisible windows
    CGFloat opacity = MAX(0.1, MIN(1.0, gTransparencyConfig.value));
    
    // Apply opacity to all subviews
    NSArray *subviews = [contentView.subviews copy];
    
    // Find and remove any existing red background
    NSView *existingBackground = nil;
    for (NSView *view in subviews) {
        if (CGColorEqualToColor(view.layer.backgroundColor, [[NSColor redColor] CGColor])) {
            existingBackground = view;
            [view removeFromSuperview];
            break;
        }
    }
    
    // Create or update red background
    NSView *redBackgroundView = existingBackground ?: [[NSView alloc] initWithFrame:contentView.bounds];
    redBackgroundView.wantsLayer = YES;
    redBackgroundView.layer.backgroundColor = [[NSColor redColor] CGColor];
    redBackgroundView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    
    // Add background at the bottom
    [contentView addSubview:redBackgroundView positioned:NSWindowBelow relativeTo:nil];
    
    // Update opacity for other views
    for (NSView *subview in subviews) {
        if (subview != existingBackground) {
            subview.alphaValue = opacity;
        }
    }
    
    // Update window properties
    self.backgroundColor = [NSColor clearColor];
    self.opaque = NO;
}

@end