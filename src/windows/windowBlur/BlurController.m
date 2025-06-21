//
//  BlurController.m
//  macwmfx
//
//  Created by Alex "aspauldingcode" on 11/13/24.
//  Copyright (c) 2024 Alex "aspauldingcode". All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "../../headers/macwmfx_globals.h"
#import <CoreImage/CoreImage.h>
#import <objc/runtime.h>
#import <QuartzCore/QuartzCore.h>

// #import <CoreImage/CoreImage.h>
// #import <objc/runtime.h>
// #import <QuartzCore/QuartzCore.h>

// static void *BlurViewKey = &BlurViewKey;
// static void *BackdropViewKey = &BackdropViewKey;

// // This controller adds blur effects to windows
// ZKSwizzleInterface(BS_NSWindow_Blur, NSWindow, NSWindow)

// @implementation BS_NSWindow_Blur

// - (void)makeKeyAndOrderFront:(id)sender {
//     ZKOrig(void, sender);
    
//     // Skip if this is not a regular window (e.g., menu, tooltip, etc.)
//     if (!(self.styleMask & NSWindowStyleMaskTitled)) return;
    
//     // Skip if window is in fullscreen
//     if (self.styleMask & NSWindowStyleMaskFullScreen) {
//         // Remove blur when entering fullscreen
//         [self removeBlurEffect];
//         return;
//     }
    
//     // Subscribe to window resize notifications
//     [[NSNotificationCenter defaultCenter] addObserver:self
//                                           selector:@selector(windowDidResize:)
//                                               name:NSWindowDidResizeNotification
//                                             object:self];
    
//     [self setupBlurEffect];
// }

// - (void)windowDidResize:(NSNotification *)notification {
//     // Skip if in fullscreen
//     if (self.styleMask & NSWindowStyleMaskFullScreen) return;
    
//     // Update blur effect on resize
//     [self setupBlurEffect];
// }

// - (void)removeBlurEffect {
//     NSVisualEffectView *existingBlur = objc_getAssociatedObject(self, BlurViewKey);
//     NSView *existingBackdrop = objc_getAssociatedObject(self, BackdropViewKey);
    
//     if (existingBlur) {
//         [existingBlur removeFromSuperview];
//         objc_setAssociatedObject(self, BlurViewKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
//     }
    
//     if (existingBackdrop) {
//         [existingBackdrop removeFromSuperview];
//         objc_setAssociatedObject(self, BackdropViewKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
//     }
    
//     // Reset window properties
//     self.backgroundColor = [NSColor windowBackgroundColor];
//     self.opaque = YES;
// }

// - (void)makeViewTransparent:(NSView *)view {
//     view.wantsLayer = YES;
//     view.layer.backgroundColor = [NSColor clearColor].CGColor;
    
//     // Recursively make all subviews transparent
//     for (NSView *subview in view.subviews) {
//         [self makeViewTransparent:subview];
//     }
// }

// - (void)setupBlurEffect {
//     if (!gBlurConfig.enabled) return;
    
//     // Skip if this is not a regular window
//     if (!(self.styleMask & NSWindowStyleMaskTitled)) return;
    
//     // Skip if in fullscreen
//     if (self.styleMask & NSWindowStyleMaskFullScreen) {
//         [self removeBlurEffect];
//         return;
//     }
    
//     NSView *contentView = [self contentView];
//     if (!contentView) return;
    
//     // Make all existing views transparent
//     [self makeViewTransparent:contentView];
    
//     // Create backdrop view
//     NSView *backdropView = [[NSView alloc] initWithFrame:contentView.bounds];
//     backdropView.wantsLayer = YES;
//     backdropView.layer.backgroundColor = [NSColor clearColor].CGColor;
//     backdropView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    
//     // Add backdrop at the very bottom
//     [contentView addSubview:backdropView positioned:NSWindowBelow relativeTo:nil];
//     objc_setAssociatedObject(self, BackdropViewKey, backdropView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
//     // Create the main blur effect view
//     NSVisualEffectView *blurView = [[NSVisualEffectView alloc] initWithFrame:contentView.bounds];
//     blurView.blendingMode = NSVisualEffectBlendingModeBehindWindow;
//     blurView.material = NSVisualEffectMaterialWindowBackground;
//     blurView.state = NSVisualEffectStateActive;
//     blurView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    
//     // Add blur effect above backdrop but below other content
//     [contentView addSubview:blurView positioned:NSWindowBelow relativeTo:nil];
//     objc_setAssociatedObject(self, BlurViewKey, blurView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
//     // Make window transparent
//     self.backgroundColor = [NSColor clearColor];
//     self.opaque = NO;
    
//     // Apply blur effect to all content subviews
//     for (NSView *subview in [contentView.subviews copy]) {
//         if (subview != blurView && subview != backdropView) {
//             NSVisualEffectView *subBlur = [[NSVisualEffectView alloc] initWithFrame:subview.bounds];
//             subBlur.blendingMode = NSVisualEffectBlendingModeBehindWindow;
//             subBlur.material = NSVisualEffectMaterialWindowBackground;
//             subBlur.state = NSVisualEffectStateActive;
//             subBlur.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
//             [subview addSubview:subBlur positioned:NSWindowBelow relativeTo:nil];
//         }
//     }
// }

// @end