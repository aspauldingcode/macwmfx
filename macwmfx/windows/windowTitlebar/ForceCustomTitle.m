//
//  ForceCustomTitle.m
//  macwmfx
//
//  Created by Alex "aspauldingcode" on 11/13/24.
//  Copyright (c) 2024 Alex "aspauldingcode". All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "../../headers/macwmfx_globals.h"

ZKSwizzleInterface(BS_NSWindow_TitleBar_Custom, NSWindow, NSWindow)

@implementation BS_NSWindow_TitleBar_Custom

- (void)makeKeyAndOrderFront:(id)sender {
    ZKOrig(void, sender);
    
    // Skip if this is not a regular window
    if ([self isKindOfClass:[NSPanel class]] || [self isKindOfClass:[NSMenu class]]) return;
    
    // Set custom title if configured
    if (gTitlebarConfig.customTitle && gTitlebarConfig.customTitle[0] != '\0') {
        [(NSWindow *)self setTitle:@(gTitlebarConfig.customTitle)];
    }
}

- (void)setTitle:(NSString *)title {
    // Only override if custom title is configured
    if (gTitlebarConfig.customTitle && gTitlebarConfig.customTitle[0] != '\0') {
        ZKOrig(void, @(gTitlebarConfig.customTitle));
    } else {
        ZKOrig(void, title);
    }
}

@end