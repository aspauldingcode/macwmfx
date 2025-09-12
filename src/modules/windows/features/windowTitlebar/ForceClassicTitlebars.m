// //
// //  ForceClassicTitlebars.m
// //  macwmfx
// //
// //  Created by Alex "aspauldingcode" on 11/13/24.
// //  Copyright (c) 2024 Alex "aspauldingcode". All rights reserved.
// //

// #import <Cocoa/Cocoa.h>
// #import <objc/runtime.h>
// #import "../../headers/macwmfx_globals.h"

// ZKSwizzleInterface(BS_NSWindow_TitleBar_Classic, NSWindow, NSWindow)

// @implementation BS_NSWindow_TitleBar_Classic

// static const CGFloat kForcedTitlebarHeight = 50.0;

// - (void)makeKeyAndOrderFront:(id)sender {
//     ZKOrig(void, sender);
    
//     // Skip if this is not a regular window
//     if ([self isKindOfClass:[NSPanel class]] || [self isKindOfClass:[NSMenu class]]) return;
    
//     // Force classic titlebar if the config has classic titlebars enabled
//     if (gTitlebarConfig.forceClassic) {
//         [self forceClassicTitleBar];
//     }
// }

// - (void)forceClassicTitleBar {
//     NSWindow *window = (NSWindow *)self;
//     window.titlebarAppearsTransparent = NO;
//     window.titleVisibility = NSWindowTitleVisible;
//     window.styleMask = (window.styleMask & ~(NSWindowStyleMaskFullSizeContentView | NSWindowStyleMaskUnifiedTitleAndToolbar)) |
//                        (NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskMiniaturizable | NSWindowStyleMaskResizable);
//     window.toolbarStyle = NSWindowToolbarStyleExpanded;

//     NSView *titlebarView = [window standardWindowButton:NSWindowCloseButton].superview.superview;
//     if (titlebarView) {
//         titlebarView.frame = (NSRect){.origin = {titlebarView.frame.origin.x, window.frame.size.height - kForcedTitlebarHeight}, .size = {titlebarView.frame.size.width, kForcedTitlebarHeight}};
//         NSView *contentView = window.contentView;
//         contentView.frame = (NSRect){.origin = {contentView.frame.origin.x, 0}, .size = {contentView.frame.size.width, window.frame.size.height - kForcedTitlebarHeight}};
//         titlebarView.autoresizingMask = NSViewNotSizable;
//         contentView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;

//         for (NSButton *button in @[[window standardWindowButton:NSWindowCloseButton], [window standardWindowButton:NSWindowMiniaturizeButton], [window standardWindowButton:NSWindowZoomButton]]) {
//             if (button) {
//                 button.frame = (NSRect){.origin = {button.frame.origin.x, (kForcedTitlebarHeight - button.frame.size.height) / 2}, .size = button.frame.size};
//             }
//         }
//     }

//     if (window.delegate != (id<NSWindowDelegate>)self) {
//         window.delegate = (id<NSWindowDelegate>)self;
//     }

//     [self swizzleTitlebarMethods];
// }

// - (void)windowDidResize:(NSNotification *)notification {
//     NSWindow *window = notification.object;
//     if (![window isKindOfClass:[NSPanel class]] && ![window isKindOfClass:[NSMenu class]]) {
//         [self enforceTitlebarConstraints:window];
//     }
// }

// - (void)enforceTitlebarConstraints:(NSWindow *)window {
//     [self forceClassicTitleBar];
// }

// - (void)swizzleTitlebarMethods {
//     static dispatch_once_t onceToken;
//     dispatch_once(&onceToken, ^{
//         [self swizzleOriginalSelector:@selector(setTitlebarAppearsTransparent:) withSwizzledSelector:@selector(swizzled_setTitlebarAppearsTransparent:)];
//         [self swizzleOriginalSelector:@selector(setTitleVisibility:) withSwizzledSelector:@selector(swizzled_setTitleVisibility:)];
//         [self swizzleOriginalSelector:@selector(setStyleMask:) withSwizzledSelector:@selector(swizzled_setStyleMask:)];
//         [self swizzleOriginalSelector:@selector(setToolbarStyle:) withSwizzledSelector:@selector(swizzled_setToolbarStyle:)];
//         [self swizzleOriginalSelector:@selector(setContentView:) withSwizzledSelector:@selector(swizzled_setContentView:)];
//         [self swizzleOriginalSelector:@selector(setFrame:display:) withSwizzledSelector:@selector(swizzled_setFrame:display:)];
//     });
// }

// - (void)swizzleOriginalSelector:(SEL)originalSelector withSwizzledSelector:(SEL)swizzledSelector {
//     Method originalMethod = class_getInstanceMethod([self class], originalSelector);
//     Method swizzledMethod = class_getInstanceMethod([self class], swizzledSelector);
//     if (class_addMethod([self class], originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod))) {
//         class_replaceMethod([self class], swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
//     } else {
//         method_exchangeImplementations(originalMethod, swizzledMethod);
//     }
// }

// - (void)swizzled_setTitlebarAppearsTransparent:(BOOL)flag {
//     [self swizzled_setTitlebarAppearsTransparent:NO];
// }

// - (void)swizzled_setTitleVisibility:(NSWindowTitleVisibility)visibility {
//     [self swizzled_setTitleVisibility:NSWindowTitleVisible];
// }

// - (void)swizzled_setStyleMask:(NSWindowStyleMask)styleMask {
//     [self swizzled_setStyleMask:(NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskMiniaturizable | NSWindowStyleMaskResizable)];
// }

// - (void)swizzled_setToolbarStyle:(NSWindowToolbarStyle)toolbarStyle {
//     [self swizzled_setToolbarStyle:NSWindowToolbarStyleExpanded];
// }

// - (void)swizzled_setContentView:(NSView *)contentView {
//     [self swizzled_setContentView:contentView];
//     [self forceClassicTitleBar];
// }

// - (void)swizzled_setFrame:(NSRect)frameRect display:(BOOL)flag {
//     [self swizzled_setFrame:frameRect display:flag];
//     [self enforceTitlebarConstraints:(NSWindow *)self];
// }

// @end