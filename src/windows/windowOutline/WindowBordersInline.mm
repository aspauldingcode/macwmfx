// // //
// // //  WindowBordersInline.m
// // //  macwmfx
// // //
// // //  Created by Alex "aspauldingcode" on 11/13/24.
// // //  Copyright (c) 2024 Alex "aspauldingcode". All rights reserved.
// // //

// #import <Cocoa/Cocoa.h>
// #import "../../headers/macwmfx_globals.h"
// #import <QuartzCore/QuartzCore.h>

// Hey I couldn't figure this out. How did you do this?
// — Today at 1:58 PM
// C++ hook
// — Today at 1:58 PM
// OH
// — Today at 2:02 PM
// force the inactive shadow, hook the data function for the shadow and bam 



// @interface NSWindow (Private)
// - (BOOL)_getCornerRadius:(CGFloat *)radius;
// @end

// ZKSwizzleInterface(BS_NSWindow_BordersInline, NSWindow, NSWindow)

// @implementation BS_NSWindow_BordersInline {
//     BOOL _isExitingFullscreen;
// }

// + (void)initialize {
//     if (self == [BS_NSWindow_BordersInline class]) {
//         // Only log if outlines are enabled
//         if (gOutlineConfig.enabled) {
//             NSLog(@"[macwmfx] Window inline border controller initialized");
//         }
//     }
// }

// - (BOOL)shouldProcessWindowEvents {
//     return gOutlineConfig.enabled && 
//            [gOutlineConfig.type isEqualToString:@"inline"] &&
//            [self isKindOfClass:[NSWindow class]] &&
//            ![self isKindOfClass:[NSPanel class]] &&
//            (self.styleMask & NSWindowStyleMaskTitled);
// }

// - (void)updateBorder {
//     @try {
//         // Skip if window is invalid or in transition
//         if (!self.contentView ||
//             self.isReleasedWhenClosed ||
//             _isExitingFullscreen) {
//             return;
//         }
        
//         // Get frame view before proceeding
//         NSView *frameView = [self.contentView superview];
//         if (!frameView) return;
        
//         // Skip if disabled or wrong type
//         if (!gOutlineConfig.enabled ||
//             ![gOutlineConfig.type isEqualToString:@"inline"]) {
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
//         NSLog(@"[macwmfx] Error updating inline border: %@", e);
//         [self clearBorder];
//     }
// }

// - (void)clearBorder {
//     @try {
//         NSView *frameView = [self.contentView superview];
//         if (!frameView) return;
        
//         frameView.wantsLayer = YES;
//         [CATransaction begin];
//         [CATransaction setDisableActions:YES];
        
//         // Reset all layer properties
//         frameView.layer.borderWidth = 0;
//         frameView.layer.borderColor = nil;
//         frameView.layer.cornerRadius = 0;
        
//         [CATransaction commit];
//     } @catch (NSException *e) {
//         NSLog(@"[macwmfx] Error clearing inline border: %@", e);
//     }
// }

// - (void)makeKeyAndOrderFront:(id)sender {
//     ZKOrig(void, sender);
//     if ([self shouldProcessWindowEvents]) {
//         [self updateBorder];
//     }
// }

// - (void)becomeKeyWindow {
//     ZKOrig(void);
//     if ([self shouldProcessWindowEvents]) {
//         [self updateBorder];
//     }
// }

// - (void)resignKeyWindow {
//     ZKOrig(void);
//     if ([self shouldProcessWindowEvents]) {
//         [self updateBorder];
//     }
// }

// - (void)windowWillEnterFullScreen:(NSNotification *)notification {
//     if ([self shouldProcessWindowEvents]) {
//         [self clearBorder];
//     }
// }

// - (void)windowDidEnterFullScreen:(NSNotification *)notification {
//     if ([self shouldProcessWindowEvents]) {
//         [self clearBorder];
//     }
// }

// - (void)windowWillExitFullScreen:(NSNotification *)notification {
//     if ([self shouldProcessWindowEvents]) {
//         _isExitingFullscreen = YES;
//         [self clearBorder];
//     }
// }

// - (void)windowDidExitFullScreen:(NSNotification *)notification {
//     if ([self shouldProcessWindowEvents]) {
//         _isExitingFullscreen = NO;
//         dispatch_async(dispatch_get_main_queue(), ^{
//             [self updateBorder];
//         });
//     }
// }

// - (void)setFrame:(NSRect)frameRect display:(BOOL)flag {
//     ZKOrig(void, frameRect, flag);
//     if ([self shouldProcessWindowEvents] && !_isExitingFullscreen) {
//         [self updateBorder];
//     }
// }

// @end