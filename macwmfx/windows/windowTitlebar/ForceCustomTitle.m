//
//  ForceCustomTitle.m
//  macwmfx
//
//  Created by Alex "aspauldingcode" on 11/13/24.
//  Copyright (c) 2024 Alex "aspauldingcode". All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "../../headers/macwmfx_globals.h"

ZKSwizzleInterface(BS_NSWindow_CustomTitle, NSWindow, NSWindow)

@implementation BS_NSWindow_CustomTitle

+ (void)load {
    // Register for config change notifications
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self
                                                      selector:@selector(handleConfigChange:)
                                                          name:@"com.macwmfx.configChanged"
                                                        object:nil];
}

+ (void)handleConfigChange:(NSNotification *)notification {
    // Only update titles if custom titles are enabled
    if (!gCustomTitleConfig.enabled) {
        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        // Update all window titles
        for (NSWindow *window in [NSApp windows]) {
            @try {
                if ([window isKindOfClass:[NSWindow class]] && (window.styleMask & NSWindowStyleMaskTitled)) {
                    // Store original title before any custom title was applied
                    NSString *originalTitle = window.representedFilename ?: window.title;
                    if (originalTitle) {
                        // Trigger our swizzled setTitle: method to update based on new config
                        [window setTitle:originalTitle];
                    }
                }
            } @catch (NSException *exception) {
                NSLog(@"[macwmfx] Error updating window title: %@", exception);
            }
        }
    });
}

// Helper method that retrieves a custom title via Key-Value Coding.
// This avoids direct use of the undeclared "titlebar" property.
- (NSString *)customTitleFromTitlebar {
    NSString *customTitle = nil;
    @try {
        id titlebar = [self valueForKey:@"titlebar"];
        if (titlebar) {
            id customTitleObj = [titlebar valueForKey:@"customTitle"];
            if (customTitleObj) {
                customTitle = [customTitleObj valueForKey:@"title"];
            }
        }
    } @catch (NSException *exception) {
        // If the key is undefined, just ignore and fall back.
    }
    return customTitle;
}

- (void)makeKeyAndOrderFront:(id)sender {
    @try {
        ZKOrig(void, sender);
        
        if (!(self.styleMask & NSWindowStyleMaskTitled))
            return;
        
        // Force update title state when the window becomes key.
        NSString *currentTitle = self.title;
        if (currentTitle) {
            [self setTitle:currentTitle];
            [self displayIfNeeded];
        }
    } @catch (NSException *exception) {
        NSLog(@"[macwmfx] Error in makeKeyAndOrderFront: %@", exception);
    }
}

- (void)setTitle:(NSString *)title {
    @try {
        if (!(self.styleMask & NSWindowStyleMaskTitled)) {
            ZKOrig(void, title);
            return;
        }
        
        NSString *finalTitle = title;
        
        // Only modify title if custom titles are enabled
        if (gCustomTitleConfig.enabled && gCustomTitleConfig.title) {
            finalTitle = @(gCustomTitleConfig.title);
            NSLog(@"[macwmfx] Applying custom title: %@", finalTitle);
        }
        
        if (finalTitle) {
            ZKOrig(void, finalTitle);
        }
    } @catch (NSException *exception) {
        NSLog(@"[macwmfx] Error setting title: %@", exception);
        // Fallback to original title if there's an error
        if (title) {
            ZKOrig(void, title);
        }
    }
}

- (void)setTitleWithRepresentedFilename:(NSString *)filename {
    @try {
        if (!(self.styleMask & NSWindowStyleMaskTitled)) {
            ZKOrig(void, filename);
            return;
        }
        
        NSString *finalTitle = filename;
        
        // Only modify title if custom titles are enabled
        if (gCustomTitleConfig.enabled && gCustomTitleConfig.title) {
            finalTitle = @(gCustomTitleConfig.title);
            NSLog(@"[macwmfx] Applying custom title: %@", finalTitle);
        }
        
        if (finalTitle) {
            ZKOrig(void, finalTitle);
        }
    } @catch (NSException *exception) {
        NSLog(@"[macwmfx] Error setting title with filename: %@", exception);
        // Fallback to original filename if there's an error
        if (filename) {
            ZKOrig(void, filename);
        }
    }
}

@end