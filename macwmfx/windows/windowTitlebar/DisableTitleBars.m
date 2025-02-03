// //
// //  DisableTitleBars.m
// //  macwmfx
// //
// //  Created by Alex "aspauldingcode" on 11/13/24.
// //  Copyright (c) 2024 Alex "aspauldingcode". All rights reserved.
// //

#import <Cocoa/Cocoa.h>
#import "../../headers/macwmfx_globals.h"

ZKSwizzleInterface(BS_NSWindow_TitleBar, NSWindow, NSWindow)

@implementation BS_NSWindow_TitleBar

+ (void)initialize {
    if (self == [BS_NSWindow_TitleBar class]) {
        // Register for config changes
        [[NSDistributedNotificationCenter defaultCenter] addObserver:self
                                                          selector:@selector(handleConfigChange:)
                                                              name:@"com.macwmfx.configChanged"
                                                            object:nil
                                                suspensionBehavior:NSNotificationSuspensionBehaviorDeliverImmediately];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                   selector:@selector(handleConfigChange:)
                                                       name:@"com.macwmfx.configChanged"
                                                     object:nil];
        
        NSLog(@"[macwmfx] Titlebar controller initialized");
    }
}

+ (void)handleConfigChange:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateAllWindowTitlebars];
    });
}

+ (void)updateAllWindowTitlebars {
    NSLog(@"[macwmfx] Updating all window titlebars. Enabled=%d", gTitlebarConfig.enabled);
    
    for (NSWindow *window in [NSApp windows]) {
        if (![window isKindOfClass:[NSWindow class]]) continue;
        if (!(window.styleMask & NSWindowStyleMaskTitled)) continue;
        
        [self updateTitlebarForWindow:window];
    }
}

+ (void)updateTitlebarForWindow:(NSWindow *)window {
    if (!gTitlebarConfig.enabled) {
        window.titlebarAppearsTransparent = YES;
        window.titleVisibility = NSWindowTitleHidden;
        window.styleMask |= NSWindowStyleMaskFullSizeContentView;
        window.contentView.wantsLayer = YES;
    } else {
        window.titlebarAppearsTransparent = NO;
        window.titleVisibility = NSWindowTitleVisible;
        window.styleMask &= ~NSWindowStyleMaskFullSizeContentView;
    }
    
    [window displayIfNeeded];
}

- (void)makeKeyAndOrderFront:(id)sender {
    ZKOrig(void, sender);
    
    // Skip if this is not a regular window (e.g., menu, tooltip, etc.)
    if (!(self.styleMask & NSWindowStyleMaskTitled)) return;
    
    [BS_NSWindow_TitleBar updateTitlebarForWindow:(NSWindow *)self];
}

- (void)orderFront:(id)sender {
    ZKOrig(void, sender);
    
    if (!(self.styleMask & NSWindowStyleMaskTitled)) return;
    
    [BS_NSWindow_TitleBar updateTitlebarForWindow:(NSWindow *)self];
}

+ (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
}

@end