//
//  CornerRadiusController.m
//  macwmfx
//
//  Created by Alex "aspauldingcode" on 11/13/24.
//  Copyright (c) 2024 Alex "aspauldingcode". All rights reserved.
//

#import "macwmfx_globals.h"

ZKSwizzleInterface(BS_NSWindow_CornerRadius, NSWindow, NSWindow)

@implementation BS_NSWindow_CornerRadius

- (id)_cornerMask {
    if (!(self.styleMask & NSWindowStyleMaskTitled)) {
        return ZKOrig(id);
    }
   NSImage *squareCornerMask = [[NSImage alloc] initWithSize:NSMakeSize(1, 1)];
    [squareCornerMask lockFocus];
    [[NSColor whiteColor] set];
    NSRectFill(NSMakeRect(0, 0, 1, 1));
    [squareCornerMask unlockFocus];
    return squareCornerMask;
}

@end

ZKSwizzleInterface(BS_TitlebarDecorationView, _NSTitlebarDecorationView, NSView)

@implementation BS_TitlebarDecorationView

- (void)viewDidMoveToWindow {
    ZKOrig(void);
    if (self.window.styleMask & NSWindowStyleMaskTitled) {
        self.hidden = YES;
    }
}

- (void)drawRect:(NSRect)dirtyRect {
    if (self.window.styleMask & NSWindowStyleMaskTitled) {
        return;
    }
    ZKOrig(void);
}

@end