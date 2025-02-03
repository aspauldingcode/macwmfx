//
//  DisableWindowShadow.m
//  macwmfx
//
//  Created by Alex "aspauldingcode" on 11/13/24.
//  Copyright (c) 2024 Alex "aspauldingcode". All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "../../headers/macwmfx_globals.h"

ZKSwizzleInterface(BS_NSWindow_Shadow, NSWindow, NSWindow)

@implementation BS_NSWindow_Shadow

+ (void)initialize {
    if (self == [BS_NSWindow_Shadow class]) {
        // Register for notifications on the default notification center
        [[NSNotificationCenter defaultCenter] addObserver:self
                                               selector:@selector(updateAllWindowShadows)
                                                   name:@"com.macwmfx.configChanged"
                                                 object:nil];
        
        // Also register on the distributed notification center
        [[NSDistributedNotificationCenter defaultCenter] addObserver:self
                                                          selector:@selector(updateAllWindowShadows)
                                                              name:@"com.macwmfx.configChanged"
                                                            object:nil
                                                suspensionBehavior:NSNotificationSuspensionBehaviorDeliverImmediately];
        
        NSLog(@"[macwmfx] Shadow controller initialized - listening for config changes");
    }
}

+ (void)updateAllWindowShadows {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"[macwmfx] Updating all window shadows. Shadow enabled=%d", gShadowConfig.enabled);
        
        for (NSWindow *window in [NSApp windows]) {
            if (![window isKindOfClass:[NSWindow class]]) continue;
            if (!(window.styleMask & NSWindowStyleMaskTitled)) continue;
            
            // Force update the shadow state
            [window setHasShadow:NO];  // Reset state
            [window setHasShadow:gShadowConfig.enabled];  // Apply new state
            
            // Force window to update
            [window displayIfNeeded];
            
            NSLog(@"[macwmfx] Updated window shadow: %@", window);
        }
    });
}

- (void)makeKeyAndOrderFront:(id)sender {
    ZKOrig(void, sender);
    
    if (!(self.styleMask & NSWindowStyleMaskTitled)) return;
    
    // Force update shadow state when window becomes key
    [(NSWindow *)self setHasShadow:NO];  // Reset state
    [(NSWindow *)self setHasShadow:gShadowConfig.enabled];  // Apply new state
    [(NSWindow *)self displayIfNeeded];
}

- (void)setHasShadow:(BOOL)hasShadow {
    if (!(self.styleMask & NSWindowStyleMaskTitled)) {
        ZKOrig(void, hasShadow);
        return;
    }
    
    // Always respect the global shadow config
    BOOL finalState = gShadowConfig.enabled ? hasShadow : NO;
    ZKOrig(void, finalState);
}

+ (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
}

@end