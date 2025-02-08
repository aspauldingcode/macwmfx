//
//  TitlebarAesthetics.m
//  macwmfx
//
//  Modified to resolve compilation errors
//

#import <AppKit/AppKit.h>
#import "../../headers/macwmfx_globals.h"

// Removed duplicate forward declarations for NSTextField and NSColor

// Compatibility macros for different SDK versions
#ifndef NSWindowStyleMaskFullSizeContentView
#define NSWindowStyleMaskFullSizeContentView (1 << 15)
#endif

ZKSwizzleInterface(BS_NSWindow_TitleColor, NSWindow, NSWindow)

@implementation BS_NSWindow_TitleColor

+ (void)initialize {
    if (self == [BS_NSWindow_TitleColor class]) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(updateAllTitlebarColors)
                                                     name:@"com.macwmfx.configChanged"
                                                   object:nil];
        
        [[NSDistributedNotificationCenter defaultCenter] addObserver:self
                                                            selector:@selector(updateAllTitlebarColors)
                                                                name:@"com.macwmfx.configChanged"
                                                              object:nil
                                                  suspensionBehavior:NSNotificationSuspensionBehaviorDeliverImmediately];
        
        NSLog(@"[macwmfx] Titlebar aesthetics controller initialized");
    }
}

+ (void)updateAllTitlebarColors {
    dispatch_async(dispatch_get_main_queue(), ^{
        for (NSWindow *window in [NSApp windows]) {
            if ([window isKindOfClass:ZKClass(BS_NSWindow_TitleColor)]) {
                [(BS_NSWindow_TitleColor *)window updateTitlebarColor];
            }
        }
    });
}

- (NSTextField *)findOriginalTitleTextField {
    NSView *themeFrame = [self contentView].superview;
    
    for (NSView *view in themeFrame.subviews) {
        NSString *className = NSStringFromClass([view class]);
        if ([className containsString:@"NSTitlebar"]) {
            for (NSView *subview in view.subviews) {
                if ([subview isKindOfClass:[NSTextField class]] &&
                   [(NSTextField *)subview stringValue] == self.title) {
                    return (NSTextField *)subview;
                }
            }
        }
    }
    return nil;
}

- (NSColor *)calculateForegroundColor {
    // Implement your color calculation logic
    if (gTitlebarConfig.customColor.enabled) {
        return self.isKeyWindow 
            ? gTitlebarConfig.customColor.activeForeground 
            : gTitlebarConfig.customColor.inactiveForeground;
    }
    return self.isKeyWindow ? [NSColor labelColor] : [NSColor secondaryLabelColor];
}

- (NSColor *)calculateBackgroundColor {
    // Implement your background color calculation
    if (gTitlebarConfig.customColor.enabled) {
        return self.isKeyWindow 
            ? gTitlebarConfig.customColor.activeBackground 
            : gTitlebarConfig.customColor.inactiveBackground;
    }
    return gTitlebarConfig.aesthetics.activeColor;
}

- (void)updateTitlebarColor {
    // Skip for panels
    if ([self isKindOfClass:[NSPanel class]]) return;

    // Access styleMask through cast to NSWindow
    NSWindow *window = (NSWindow *)self;

    if (!gTitlebarConfig.enabled) {
        // If titlebar is disabled, make it transparent and hide title
        window.titlebarAppearsTransparent = YES;
        window.titleVisibility = NSWindowTitleHidden;
        window.styleMask |= NSWindowStyleMaskFullSizeContentView;
        return;
    }

    // Titlebar is enabled, show it normally
    window.titlebarAppearsTransparent = NO;
    window.titleVisibility = NSWindowTitleVisible;
    window.styleMask &= ~NSWindowStyleMaskFullSizeContentView;

    // Apply custom colors if enabled
    if (gTitlebarConfig.customColor.enabled) {
        NSTextField *titleField = [self findOriginalTitleTextField];
        NSColor *foregroundColor = [self calculateForegroundColor];
        NSColor *backgroundColor = [self calculateBackgroundColor];

        if (titleField) {
            titleField.textColor = foregroundColor;
            titleField.font = [NSFont systemFontOfSize:13 weight:NSFontWeightSemibold];
        }

        [self modifyTitlebarBackground:backgroundColor];
    }
}

- (void)modifyTitlebarBackground:(NSColor *)color {
    NSView *themeFrame = [self contentView].superview;
    
    for (NSView *view in themeFrame.subviews) {
        NSString *className = NSStringFromClass([view class]);
        if ([className containsString:@"NSTitlebar"] &&
            [view respondsToSelector:@selector(layer)] &&
            view.frame.size.height <= 28) {
            
            view.wantsLayer = YES;
            view.layer.backgroundColor = color.CGColor;
            break;
        }
    }
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

+ (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
}

@end