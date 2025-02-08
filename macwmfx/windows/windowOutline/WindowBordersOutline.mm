// //
// //  WindowBordersOutline.m
// //  macwmfx
// //
// //  Created by Alex "aspauldingcode" on 11/13/24.
// //  Copyright (c) 2024 Alex "aspauldingcode". All rights reserved.
// //

// #import "../../headers/macwmfx_globals.h"
// #import <QuartzCore/QuartzCore.h>

// Hey I couldn't figure this out. How did you do this?
// — Today at 1:58 PM
// C++ hook
// — Today at 1:58 PM
// OH
// — Today at 2:02 PM
// force the inactive shadow, hook the data function for the shadow and bam 


// @interface BSOutlineBorderWindow : NSPanel
// @property (nonatomic, weak) NSWindow *targetWindow;
// @end

// @implementation BSOutlineBorderWindow

// - (instancetype)initWithTargetWindow:(NSWindow *)window {
//     self = [super initWithContentRect:window.frame
//                           styleMask:NSWindowStyleMaskBorderless
//                             backing:NSBackingStoreBuffered
//                               defer:YES];
//     if (self) {
//         self.targetWindow = window;
//         self.backgroundColor = [NSColor clearColor];
//         self.opaque = NO;
//         self.hasShadow = NO;
//         self.level = NSNormalWindowLevel - 1;
//         self.ignoresMouseEvents = YES;
        
//         NSView *contentView = self.contentView;
//         contentView.wantsLayer = YES;
//         contentView.layer = [CALayer layer];
//     }
//     return self;
// }

// - (void)updateBorderFrame {
//     if (!self.targetWindow) return;
    
//     NSRect targetFrame = self.targetWindow.frame;
//     CGFloat borderWidth = MIN(MAX(gOutlineConfig.width, 1), 10);
//     NSRect borderFrame = NSInsetRect(targetFrame, -borderWidth, -borderWidth);
    
//     [self setFrame:borderFrame display:YES];
    
//     CALayer *borderLayer = self.contentView.layer;
//     borderLayer.frame = self.contentView.bounds;
//     borderLayer.borderWidth = borderWidth;
//     borderLayer.cornerRadius = MIN(gOutlineConfig.cornerRadius, 40);
    
//     NSColor *borderColor = self.targetWindow.isKeyWindow ?
//         [NSColor colorWithDeviceWhite:0.0 alpha:0.3] :
//         [NSColor colorWithDeviceWhite:0.5 alpha:0.3];
        
//     if (gOutlineConfig.customColor.enabled) {
//         borderColor = self.targetWindow.isKeyWindow ? 
//             gOutlineConfig.customColor.active : 
//             gOutlineConfig.customColor.inactive;
//     }
    
//     borderLayer.borderColor = borderColor.CGColor;
// }

// @end

// ZKSwizzleInterface(BS_NSWindow_BordersOutline, NSWindow, NSWindow)

// @implementation BS_NSWindow_BordersOutline {
//     BSOutlineBorderWindow * __weak _borderWindow;
// }

// + (void)initialize {
//     if (self == [BS_NSWindow_BordersOutline class]) {
//         NSLog(@"[macwmfx] Window outline controller initialized");
//     }
// }

// - (void)updateBorder {
//     @try {
//         // Skip if disabled or wrong type
//         if (!gOutlineConfig.enabled || 
//             ![gOutlineConfig.type isEqualToString:@"outline"]) {
//             [self clearBorder];
//             return;
//         }

//         // Skip non-standard windows
//         if (![self isKindOfClass:[NSWindow class]] ||
//             [self isKindOfClass:[NSPanel class]] ||
//             !(self.styleMask & NSWindowStyleMaskTitled) ||
//             (self.styleMask & NSWindowStyleMaskFullScreen)) {
//             [self clearBorder];
//             return;
//         }

//         if (!_borderWindow) {
//             _borderWindow = [[BSOutlineBorderWindow alloc] initWithTargetWindow:self];
//         }
        
//         [_borderWindow updateBorderFrame];
//         [_borderWindow orderFront:nil];
//     } @catch (NSException *e) {
//         NSLog(@"[macwmfx] Error updating outline border: %@", e);
//         [self clearBorder];
//     }
// }

// - (void)clearBorder {
//     if (_borderWindow) {
//         [_borderWindow orderOut:nil];
//         _borderWindow = nil;
//     }
// }

// - (void)makeKeyAndOrderFront:(id)sender {
//     ZKOrig(void, sender);
//     [self updateBorder];
// }

// - (void)becomeKeyWindow {
//     ZKOrig(void);
//     [self updateBorder];
// }

// - (void)resignKeyWindow {
//     ZKOrig(void);
//     [self updateBorder];
// }

// - (void)close {
//     [self clearBorder];
//     ZKOrig(void);
// }

// - (void)windowDidEnterFullScreen:(NSNotification *)notification {
//     [self clearBorder];
// }

// - (void)windowDidExitFullScreen:(NSNotification *)notification {
//     [self updateBorder];
// }

// @end