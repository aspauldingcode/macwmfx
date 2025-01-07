//
//  WindowTransparencyController.m
//  AfloatX
//
//  Created by j on 12/6/19.
//  Copyright © 2019 j. All rights reserved.
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
    
    window.alphaValue = opacity;
    window.opaque = (opacity >= 1.0);
    window.backgroundColor = [[NSColor windowBackgroundColor] colorWithAlphaComponent:opacity];
}

@end