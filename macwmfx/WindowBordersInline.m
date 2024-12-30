#import <AppKit/AppKit.h>
#import "ZKSwizzle.h"
#import "macwmfx_globals.h"
#import <objc/runtime.h>

@interface WindowBorders : NSObject
+ (BOOL)shouldApplyBorderToWindow:(NSWindow *)window;
+ (void)applyBorderToWindow:(NSWindow *)window;
+ (void)updateBorderForWindow:(NSWindow *)window;
@end

@implementation WindowBorders

+ (void)load {
    // Only proceed if borders are enabled and type is "inline"
    if (!gOutlineEnabled || ![gOutlineType isEqualToString:@"inline"]) return;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // Register for window creation notifications
        [[NSNotificationCenter defaultCenter] addObserver:[self class]
                                               selector:@selector(windowDidCreate:)
                                                   name:NSWindowDidBecomeKeyNotification
                                                 object:nil];
        
        // Apply to all existing windows
        for (NSWindow *window in [NSApp windows]) {
            if ([WindowBorders shouldApplyBorderToWindow:window]) {
                [WindowBorders applyBorderToWindow:window];
            }
        }
    });
}

+ (void)windowDidCreate:(NSNotification *)notification {
    // Only proceed if borders are enabled and type is "inline"
    if (!gOutlineEnabled || ![gOutlineType isEqualToString:@"inline"]) return;
    
    NSWindow *window = notification.object;
    if ([self shouldApplyBorderToWindow:window]) {
        [self applyBorderToWindow:window];
    }
}

+ (BOOL)shouldApplyBorderToWindow:(NSWindow *)window {
    // First check if borders are enabled and type is "inline"
    if (!gOutlineEnabled || ![gOutlineType isEqualToString:@"inline"]) return NO;
    
    // Skip if it's not a regular window
    if (!(window.styleMask & NSWindowStyleMaskTitled)) {
        return NO;
    }
    
    // Skip system windows, panels, sheets, etc
    if (window.level != NSNormalWindowLevel) {
        return NO;
    }
    
    // Skip if it's a special window class (like panels or sheets)
    NSString *className = NSStringFromClass([window class]);
    if ([className containsString:@"Panel"] || 
        [className containsString:@"Sheet"] ||
        [className containsString:@"Popover"] ||
        [className containsString:@"HUD"]) {
        return NO;
    }
    
    return YES;
}

+ (void)updateBorderForWindow:(NSWindow *)window {
    // Only proceed if borders are enabled in config
    if (!gOutlineEnabled) return;
    
    CALayer *borderLayer = objc_getAssociatedObject(window, "borderLayer");
    if (!borderLayer) return;
    
    NSView *frameView = [[window contentView] superview];
    if (!frameView) return;
    
    // Disable implicit animations
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:0.0];
    
    // Update frame
    borderLayer.frame = frameView.layer.bounds;
    
    // Update color based on window state using config colors
    borderLayer.borderColor = window.isKeyWindow ? 
        (gOutlineActiveColor ? gOutlineActiveColor.CGColor : NSColor.controlAccentColor.CGColor) : 
        (gOutlineInactiveColor ? gOutlineInactiveColor.CGColor : NSColor.selectedContentBackgroundColor.CGColor);
    
    [NSAnimationContext endGrouping];
}

+ (void)applyBorderToWindow:(NSWindow *)window {
    // Only proceed if borders are enabled in config
    if (!gOutlineEnabled) return;
    
    // Get the window's frame view (the view that draws the window border)
    NSView *frameView = [[window contentView] superview];
    frameView.wantsLayer = YES;
    
    CALayer *layer = frameView.layer;
    if (!layer) return;
    
    // Set up corner radius from config
    layer.cornerRadius = gOutlineCornerRadius;
    
    // Create border layer if it doesn't exist
    CALayer *borderLayer = objc_getAssociatedObject(window, "borderLayer");
    if (!borderLayer) {
        borderLayer = [CALayer layer];
        
        // Disable all animations
        NSMutableDictionary *newActions = [@{
            @"bounds": [NSNull null],
            @"frame": [NSNull null],
            @"position": [NSNull null],
            @"borderColor": [NSNull null],
            @"borderWidth": [NSNull null],
            @"cornerRadius": [NSNull null],
            @"opacity": [NSNull null],
            @"sublayers": [NSNull null],
            @"contents": [NSNull null],
            @"hidden": [NSNull null],
            @"onOrderIn": [NSNull null],
            @"onOrderOut": [NSNull null],
            @"transform": [NSNull null]
        } mutableCopy];
        borderLayer.actions = newActions;
        
        objc_setAssociatedObject(window, "borderLayer", borderLayer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [layer addSublayer:borderLayer];
    }
    
    // Configure border layer using config values
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:0.0];
    
    borderLayer.frame = layer.bounds;
    borderLayer.borderWidth = gOutlineWidth;
    borderLayer.cornerRadius = gOutlineCornerRadius;
    borderLayer.zPosition = 999;
    borderLayer.opacity = 1.0;
    borderLayer.borderColor = window.isKeyWindow ? 
        (gOutlineActiveColor ? gOutlineActiveColor.CGColor : NSColor.controlAccentColor.CGColor) : 
        (gOutlineInactiveColor ? gOutlineInactiveColor.CGColor : NSColor.selectedContentBackgroundColor.CGColor);
    
    [NSAnimationContext endGrouping];
    
    // Add resize observer if not already added
    @try {
        [window addObserver:window
                forKeyPath:@"frame"
                   options:NSKeyValueObservingOptionNew
                   context:NULL];
    } @catch (NSException *exception) {
        // Observer might already be registered, that's okay
    }
}

@end

ZKSwizzleInterface(BS_NSWindow_Borders, NSWindow, NSWindow)

@implementation BS_NSWindow_Borders

- (void)makeKeyAndOrderFront:(id)sender {
    ZKOrig(void, sender);
    
    NSWindow *window = (NSWindow *)self;
    if ([WindowBorders shouldApplyBorderToWindow:window]) {
        [WindowBorders applyBorderToWindow:window];
    }
}

- (void)orderFront:(nullable id)sender {
    ZKOrig(void, sender);
    
    NSWindow *window = (NSWindow *)self;
    if ([WindowBorders shouldApplyBorderToWindow:window]) {
        [WindowBorders applyBorderToWindow:window];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                    ofObject:(id)object
                      change:(NSDictionary *)change
                     context:(void *)context {
    if ([keyPath isEqualToString:@"frame"]) {
        NSWindow *window = (NSWindow *)object;
        if ([WindowBorders shouldApplyBorderToWindow:window]) {
            [WindowBorders updateBorderForWindow:window];
        }
    }
}

- (void)becomeKeyWindow {
    ZKOrig(void);
    NSWindow *window = (NSWindow *)self;
    if ([WindowBorders shouldApplyBorderToWindow:window]) {
        [WindowBorders updateBorderForWindow:window];
    }
}

- (void)resignKeyWindow {
    ZKOrig(void);
    NSWindow *window = (NSWindow *)self;
    if ([WindowBorders shouldApplyBorderToWindow:window]) {
        [WindowBorders updateBorderForWindow:window];
    }
}

@end