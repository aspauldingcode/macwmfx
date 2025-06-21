//
//  DisableTitleBars.m
//  macwmfx
//
//  Created by Alex "aspauldingcode" on 11/13/24.
//  Copyright (c) 2024 Alex "aspauldingcode". All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
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
    if ([self isAppWhitelisted]) {
        [self disableTitlebarAlternativeForWindow:window];
    } else {
        [self disableTitlebarNormalForWindow:window];
    }
}

+ (BOOL)isAppWhitelisted {
    NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
    // Modify this whitelist as needed.
    return (bundleID && [bundleID isEqualToString:@"org.libreoffice.script"]);
}

+ (void)disableTitlebarNormalForWindow:(NSWindow *)window {
    if (!gTitlebarConfig.enabled) {
        // Disable titlebar in the normal way, even in fullscreen.
        window.titlebarAppearsTransparent = YES;
        window.titleVisibility = NSWindowTitleHidden;
        window.styleMask |= NSWindowStyleMaskFullSizeContentView;
        window.contentView.wantsLayer = YES;
        
        // Additional fix for fullscreen: hide the titlebar container view if present.
        if (window.styleMask & NSWindowStyleMaskFullScreen) {
            NSView *container = window.contentView.superview;
            for (NSView *subview in container.subviews) {
                if ([[NSStringFromClass([subview class]) lowercaseString] containsString:@"titlebar"]) {
                    subview.hidden = YES;
                }
            }
        }
    } else {
        // Restore default appearance.
        window.titlebarAppearsTransparent = NO;
        window.titleVisibility = NSWindowTitleVisible;
        window.styleMask &= ~NSWindowStyleMaskFullSizeContentView;
        
        // If in fullscreen, ensure the titlebar container view is shown.
        if (window.styleMask & NSWindowStyleMaskFullScreen) {
            NSView *container = window.contentView.superview;
            for (NSView *subview in container.subviews) {
                if ([[NSStringFromClass([subview class]) lowercaseString] containsString:@"titlebar"]) {
                    subview.hidden = NO;
                }
            }
        }
    }
    // Remove any cropping mask left from alternative method.
    if (window.contentView.layer.mask) {
        window.contentView.layer.mask = nil;
    }
    [window displayIfNeeded];
}

+ (void)disableTitlebarAlternativeForWindow:(NSWindow *)window {
    if (!gTitlebarConfig.enabled) {
        // Hide the titlebar without shifting the content.
        window.titlebarAppearsTransparent = YES;
        window.titleVisibility = NSWindowTitleHidden;
        window.styleMask |= NSWindowStyleMaskFullSizeContentView;
        window.contentView.wantsLayer = YES;
        
        if (window.contentView) {
            NSRect expectedFrame = [window contentLayoutRect];
            NSRect currentFrame = window.contentView.frame;
            // Determine the vertical offset that would have been removed by the titlebar.
            CGFloat offset = currentFrame.size.height - expectedFrame.size.height;
            if (offset > 0) {
                // Instead of moving the content, apply a mask to crop the top region.
                CAShapeLayer *maskLayer = [CAShapeLayer layer];
                maskLayer.frame = window.contentView.bounds;
                CGRect cropRect = CGRectMake(0, 0, window.contentView.bounds.size.width, window.contentView.bounds.size.height - offset);
                CGMutablePathRef path = CGPathCreateMutable();
                CGPathAddRect(path, NULL, cropRect);
                maskLayer.path = path;
                CGPathRelease(path);
                window.contentView.layer.mask = maskLayer;
            } else {
                window.contentView.layer.mask = nil;
            }
        }
        
        // Additional fix for fullscreen: hide the titlebar container view if present.
        if (window.styleMask & NSWindowStyleMaskFullScreen) {
            NSView *container = window.contentView.superview;
            for (NSView *subview in container.subviews) {
                if ([[NSStringFromClass([subview class]) lowercaseString] containsString:@"titlebar"]) {
                    subview.hidden = YES;
                }
            }
        }
        
        // Ensure the alternative update is applied even during live resize.
        if (window.inLiveResize) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)),
                           dispatch_get_main_queue(), ^{
                [self disableTitlebarAlternativeForWindow:window];
            });
        }
    } else {
        // Restore default appearance.
        window.titlebarAppearsTransparent = NO;
        window.titleVisibility = NSWindowTitleVisible;
        window.styleMask &= ~NSWindowStyleMaskFullSizeContentView;
        if (window.contentView.layer.mask) {
            window.contentView.layer.mask = nil;
        }
        
        // If in fullscreen, ensure the titlebar container view is shown.
        if (window.styleMask & NSWindowStyleMaskFullScreen) {
            NSView *container = window.contentView.superview;
            for (NSView *subview in container.subviews) {
                if ([[NSStringFromClass([subview class]) lowercaseString] containsString:@"titlebar"]) {
                    subview.hidden = NO;
                }
            }
        }
    }
    
    [window displayIfNeeded];
}

- (void)makeKeyAndOrderFront:(id)sender {
    ZKOrig(void, sender);
    
    // Skip if this is not a regular window.
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