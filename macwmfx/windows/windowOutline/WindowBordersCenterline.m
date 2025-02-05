// //
// //  WindowBordersCenterline.m
// //  macwmfx
// //
// //  Created by Alex "aspauldingcode" on 11/13/24.
// //  Copyright (c) 2024 Alex "aspauldingcode". All rights reserved.
// //

// #import <Cocoa/Cocoa.h>
// #import "../../headers/macwmfx_globals.h"
// #import <QuartzCore/QuartzCore.h>

// ZKSwizzleInterface(BS_NSWindow_BordersCenterline, NSWindow, NSWindow)

// @interface BSCenterlineBorderWindow : NSPanel
// @property (nonatomic, weak) NSWindow *targetWindow;
// @end

// @implementation BSCenterlineBorderWindow

// - (instancetype)initWithTargetWindow:(NSWindow *)window {
//     self = [super initWithContentRect:NSZeroRect
//                           styleMask:NSWindowStyleMaskBorderless
//                             backing:NSBackingStoreBuffered
//                               defer:NO];
//     if (self) {
//         self.targetWindow = window;
//         self.backgroundColor = [NSColor clearColor];
//         self.opaque = NO;
//         self.hasShadow = NO;
//         self.level = NSFloatingWindowLevel;
//         self.ignoresMouseEvents = YES;
//         self.releasedWhenClosed = NO;
//     }
//     return self;
// }

// - (void)updateBorderFrame {
//     if (!self.targetWindow) return;
    
//     NSRect targetFrame = self.targetWindow.frame;
//     CGFloat borderWidth = gOutlineConfig.width;
    
//     // For centerline, position border to overlap window edge
//     NSRect borderFrame = NSInsetRect(targetFrame, -borderWidth/2, -borderWidth/2);
//     [self setFrame:borderFrame display:YES];
// }

// @end

// @implementation BS_NSWindow_BordersCenterline {
//     BSCenterlineBorderWindow *_borderWindow;
// }

// + (void)initialize {
//     if (self == [BS_NSWindow_BordersCenterline class]) {
//         NSLog(@"[macwmfx] Window centerline border controller initialized");
//     }
// }

// - (void)updateBorder {
//     @try {
//         // Skip if disabled or wrong type
//         if (!gOutlineConfig.enabled || 
//             ![gOutlineConfig.type isEqualToString:@"centerline"]) {
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

//         NSView *frameView = [self.contentView superview];
//         if (!frameView) return;

//         frameView.wantsLayer = YES;
        
//         [CATransaction begin];
//         [CATransaction setDisableActions:YES];
        
//         frameView.layer.borderWidth = gOutlineConfig.width;
//         frameView.layer.cornerRadius = gOutlineConfig.cornerRadius;
        
//         NSColor *borderColor = self.isKeyWindow ?
//             [NSColor colorWithDeviceWhite:0.0 alpha:0.3] :
//             [NSColor colorWithDeviceWhite:0.5 alpha:0.3];
            
//         if (gOutlineConfig.customColor.enabled) {
//             borderColor = self.isKeyWindow ? 
//                 gOutlineConfig.customColor.active : 
//                 gOutlineConfig.customColor.inactive;
//         }
        
//         frameView.layer.borderColor = borderColor.CGColor;
        
//         [CATransaction commit];
//     } @catch (NSException *e) {
//         NSLog(@"[macwmfx] Error updating centerline border: %@", e);
//         [self clearBorder];
//     }
// }

// - (void)clearBorder {
//     @try {
//         NSView *frameView = [self.contentView superview];
//         if (frameView && frameView.layer) {
//             frameView.layer.borderWidth = 0;
//             frameView.layer.borderColor = nil;
//         }
//     } @catch (NSException *e) {
//         NSLog(@"[macwmfx] Error clearing centerline border: %@", e);
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

// - (void)windowDidEnterFullScreen:(NSNotification *)notification {
//     [self clearBorder];
// }

// - (void)windowDidExitFullScreen:(NSNotification *)notification {
//     [self updateBorder];
// }

// @end