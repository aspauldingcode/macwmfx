//
//  BlurController.m
//  macwmfx
//
//  Created by Alex "aspauldingcode" on 11/13/24.
//  Copyright (c) 2024 Alex "aspauldingcode". All rights reserved.
//

#import <CoreImage/CoreImage.h>
#import "macwmfx_globals.h"
#import <objc/runtime.h>
#import <QuartzCore/QuartzCore.h>

// This controller adds a red background to windows
ZKSwizzleInterface(BS_NSWindow_Blur, NSWindow, NSWindow)

@implementation BS_NSWindow_Blur

-(void)makeKeyAndOrderFront:(id)sender {
    ZKOrig(void, sender);
    [self setupRedBackgroundLayer];
}

- (void)setupRedBackgroundLayer {
    if (!gBlurConfig.enabled) return;
    
    // Skip if this is not a regular window (e.g., menu, tooltip, etc.)
    if (!(self.styleMask & NSWindowStyleMaskTitled)) return;
    
    NSView *contentView = [self contentView];
    if (!contentView) return;
    
    // Check if red background already exists
    for (NSView *subview in contentView.subviews) {
        if (CGColorEqualToColor(subview.layer.backgroundColor, [[NSColor redColor] CGColor])) {
            return;
        }
    }
    
    // Create a view for the red background
    NSView *redBackgroundView = [[NSView alloc] initWithFrame:contentView.bounds];
    redBackgroundView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    redBackgroundView.wantsLayer = YES;
    
    // Set solid red background color with no transparency
    redBackgroundView.layer.backgroundColor = [[NSColor redColor] CGColor];
    redBackgroundView.layer.opacity = 1.0;
    
    // Add background view at the bottom of the view hierarchy
    [contentView addSubview:redBackgroundView positioned:NSWindowBelow relativeTo:nil];
    
    // Make window background clear to allow red background to show through
    self.backgroundColor = [NSColor clearColor];
    self.opaque = NO;
}

@end