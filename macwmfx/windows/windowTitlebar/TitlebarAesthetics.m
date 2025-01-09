//
//  TitlebarAesthetics.m
//  macwmfx
//
//  Created by Alex "aspauldingcode" on 11/13/24.
//  Copyright (c) 2024 Alex "aspauldingcode". All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "../../headers/macwmfx_globals.h"

ZKSwizzleInterface(BS_NSWindow_TitleColor, NSWindow, NSWindow)

@implementation BS_NSWindow_TitleColor

- (void)updateTitlebarColor {
    // Skip if titlebar aesthetics are not enabled
    if (!gTitlebarConfig.aesthetics.enabled) return;
    
    // Skip if this is not a regular window
    if ([self isKindOfClass:[NSPanel class]] || [self isKindOfClass:[NSMenu class]]) return;
    
    NSView *titlebarView = [self standardWindowButton:NSWindowCloseButton].superview.superview;
    if (!titlebarView) return;
    
    titlebarView.wantsLayer = YES;
    titlebarView.layer.backgroundColor = self.isKeyWindow ? 
        gTitlebarConfig.aesthetics.activeColor.CGColor : 
        gTitlebarConfig.aesthetics.inactiveColor.CGColor;
}

- (void)makeKeyAndOrderFront:(id)sender {
    ZKOrig(void, sender);
    [self updateTitlebarColor];
}

- (void)becomeKeyWindow {
    ZKOrig(void);
    [self updateTitlebarColor];
}

- (void)resignKeyWindow {
    ZKOrig(void);
    [self updateTitlebarColor];
}

@end

