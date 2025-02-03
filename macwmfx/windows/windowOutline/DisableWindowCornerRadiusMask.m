// //
// //  CornerRadiusController.m
// //  macwmfx
// //
// //  Created by Alex "aspauldingcode" on 11/13/24.
// //  Copyright (c) 2024 Alex "aspauldingcode". All rights reserved.
// //

// // This file disables the default window corner radius mask by replacing it with a 
// // square mask. This is required for window outlining functionality to work properly,
// // as the default rounded corners would interfere with the custom border styling. 
// // By forcing square corners:
// //
// // 1. It allows the outline border to be drawn consistently around the entire window
// // 2. Prevents visual artifacts where rounded corners would clip the border corners 
// // 3. Ensures the border width appears uniform rather than being affected by radius
// // 4. Works with WindowBordersCenterline.m, WindowBordersInline.m and 
// //    WindowBordersOutline.m to provide clean border rendering
// //
// // The _cornerMask method is swizzled to return a simple 1x1 white square image 
// // instead of the default rounded mask. Additionally, the titlebar decoration view 
// // is hidden to prevent it from drawing its own rounded corners.

// #import "../../headers/macwmfx_globals.h"

// ZKSwizzleInterface(BS_NSWindow_CornerRadius, NSWindow, NSWindow)

// @implementation BS_NSWindow_CornerRadius

// - (id)_cornerMask {
//     if (!(self.styleMask & NSWindowStyleMaskTitled)) {
//         return ZKOrig(id);
//     }
//    NSImage *squareCornerMask = [[NSImage alloc] initWithSize:NSMakeSize(1, 1)];
//     [squareCornerMask lockFocus];
//     [[NSColor whiteColor] set];
//     NSRectFill(NSMakeRect(0, 0, 1, 1));
//     [squareCornerMask unlockFocus];
//     return squareCornerMask;
// }

// @end

// ZKSwizzleInterface(BS_TitlebarDecorationView, _NSTitlebarDecorationView, NSView)

// @implementation BS_TitlebarDecorationView

// - (void)viewDidMoveToWindow {
//     ZKOrig(void);
//     if (self.window.styleMask & NSWindowStyleMaskTitled) {
//         self.hidden = YES;
//     }
// }

// - (void)drawRect:(NSRect)dirtyRect {
//     if (self.window.styleMask & NSWindowStyleMaskTitled) {
//         return;
//     }
//     ZKOrig(void);
// }

// @end