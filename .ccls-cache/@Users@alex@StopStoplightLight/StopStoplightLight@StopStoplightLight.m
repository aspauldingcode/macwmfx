//
//  StopStoplightLight.m
//  StopStoplightLight
//
//  Created by Brian "Shishkabibal" on 6/25/24.
//  Copyright (c) 2024 Brian "Shishkabibal". All rights reserved.
//

#pragma mark - Library/Header Imports

@import AppKit;
@import QuartzCore;
#import "NSWindow+StopStoplightLight.h"
#import "ZKSwizzle.h"
#import <objc/runtime.h>

#include <os/log.h>
#define DLog(N, ...)                                                           \
  os_log_with_type(                                                            \
      os_log_create("com.shishkabibal.StopStoplightLight", "DEBUG"),           \
      OS_LOG_TYPE_DEFAULT, N, ##__VA_ARGS__)

#pragma mark - Global Variables

static NSString *const preferencesSuiteName =
    @"com.shishkabibal.StopStoplightLight";

// Feature flags
static BOOL enableTrafficLightsDisabler = YES;
static BOOL enableTitlebarDisabler = YES;
static BOOL enableResizability = YES;
static BOOL enableWindowBorders = YES;

#pragma mark - Main Implementation

@interface StopStoplightLight ()

@end

@implementation StopStoplightLight

+ (instancetype)sharedInstance {
  static StopStoplightLight *sharedInstance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedInstance = [[self alloc] init];
  });
  return sharedInstance;
}

+ (void)load {
  [self sharedInstance];
}

@end

#pragma mark - NSWindow Swizzling

ZKSwizzleInterface(BS_NSWindow, NSWindow, NSWindow)

@implementation BS_NSWindow

#pragma mark - Overridden Methods

- (nullable NSButton *)standardWindowButton:(NSWindowButton)b {
  return ZKOrig(NSButton *, b);
}

- (void)makeKeyAndOrderFront:(id)sender {
  ZKOrig(void, sender);

  if (enableTitlebarDisabler) {
    [self modifyTitlebarAppearance];
  }

  if (enableTrafficLightsDisabler) {
    [self hideTrafficLights];
  }

  if (enableResizability) {
    [self makeResizableToAnySize];
  }

  if (enableWindowBorders) {
    [self addWindowBorders];
  }
}

- (void)orderOut:(id)sender {
  ZKOrig(void, sender);
}

- (void)becomeKeyWindow {
  ZKOrig(void);
}

- (void)resignKeyWindow {
  ZKOrig(void);
}

- (void)setFrame:(NSRect)frameRect display:(BOOL)flag {
  ZKOrig(void, frameRect, flag);
  if (!enableWindowBorders) {
    return;
  }

  [CATransaction begin];
  [CATransaction setDisableActions:YES];
  [self updateMaskAndOutlineForWindow:(NSWindow *)self];
  [CATransaction commit];
  [self updateBorderColorForWindow:(NSWindow *)self];
  [self modifyTitlebarAppearance];
  [(NSWindow *)self display];
}

#pragma mark - Custom Methods

- (void)hideTrafficLights {
  [self hideButton:[self standardWindowButton:NSWindowCloseButton]];
  [self hideButton:[self standardWindowButton:NSWindowMiniaturizeButton]];
  [self hideButton:[self standardWindowButton:NSWindowZoomButton]];
}

- (void)hideButton:(NSButton *)button {
  button.hidden = YES;
}

- (void)modifyTitlebarAppearance {
  NSWindow *window = (NSWindow *)self;
  window.titlebarAppearsTransparent = YES;
  window.titleVisibility = NSWindowTitleHidden;
  window.styleMask |= NSWindowStyleMaskFullSizeContentView;
  window.contentView.wantsLayer = YES; // Ensure contentView is layer-backed
}

- (void)makeResizableToAnySize {
  NSWindow *window = (NSWindow *)self;
  window.styleMask |= NSWindowStyleMaskResizable;
  [window setMinSize:NSMakeSize(0.0, 0.0)];
  [window setMaxSize:NSMakeSize(CGFLOAT_MAX, CGFLOAT_MAX)];
}



#pragma mark - Window Border Methods

    /**
     * Creates a rounded rectangular path with the given bounds and corner radius.
     *
     * @param bounds The bounds of the window's content view.
     * @param cornerRadius The radius of the window's corners.
     * @return A CGMutablePathRef representing the rounded rectangular path.
     */
    - (CGMutablePathRef)createRoundedPathWithBounds:(CGRect)bounds cornerRadius:(CGFloat)cornerRadius {
        CGMutablePathRef path = CGPathCreateMutable();
        
        // Start at top-left corner
        CGPathMoveToPoint(path, NULL, cornerRadius, 0);
        
        // Top edge
        CGPathAddLineToPoint(path, NULL, bounds.size.width - cornerRadius, 0);
        
        // Top-right corner
        CGPathAddArcToPoint(path, NULL, bounds.size.width, 0, bounds.size.width, cornerRadius, cornerRadius);
        
        // Right edge
        CGPathAddLineToPoint(path, NULL, bounds.size.width, bounds.size.height - cornerRadius);
        
        // Bottom-right corner
        CGPathAddArcToPoint(path, NULL, bounds.size.width, bounds.size.height, bounds.size.width - cornerRadius, bounds.size.height, cornerRadius);
        
        // Bottom edge
        CGPathAddLineToPoint(path, NULL, cornerRadius, bounds.size.height);
        
        // Bottom-left corner
        CGPathAddArcToPoint(path, NULL, 0, bounds.size.height, 0, bounds.size.height - cornerRadius, cornerRadius);
        
        // Left edge
        CGPathAddLineToPoint(path, NULL, 0, cornerRadius);
        
        // Top-left corner
        CGPathAddArcToPoint(path, NULL, 0, 0, cornerRadius, 0, cornerRadius);
        
        CGPathCloseSubpath(path);
        
        return path;
    }
    
    /**
     * Adds borders to the window if the `enableWindowBorders` flag is set.
     * This method ensures the contentView is layer-backed, creates a mask layer,
     * and adds border and outline layers to the window's content view.
     * It also sets up notifications for window state changes and resizing.
     */
    - (void)addWindowBorders {
        if (!enableWindowBorders) {
            return;
        }
    
        NSWindow *window = (NSWindow *)self;
    
        // Ensure the contentView is layer-backed
        window.contentView.wantsLayer = YES;
    
        // Set flags for border
        CGFloat borderWidth = 2.0;
        CGFloat cornerRadius = 40.0;
    
        CALayer *contentLayer = window.contentView.layer;
        if (contentLayer) {
            // Remove existing mask and border/outline layers if they exist
            if (contentLayer.mask) {
                [contentLayer.mask removeFromSuperlayer];
                contentLayer.mask = nil;
            }
            CAShapeLayer *existingOutlineLayer = objc_getAssociatedObject(self, "outlineLayer");
            if (existingOutlineLayer) {
                [existingOutlineLayer removeFromSuperlayer];
                objc_setAssociatedObject(self, "outlineLayer", nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            }
            CAShapeLayer *existingBorderLayer = objc_getAssociatedObject(self, "borderLayer");
            if (existingBorderLayer) {
                [existingBorderLayer removeFromSuperlayer];
                objc_setAssociatedObject(self, "borderLayer", nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            }
    
            // Create a mask layer
            CAShapeLayer *maskLayer = [CAShapeLayer layer];
    
            // Create a path that subtracts the corner radius
            CGRect bounds = window.contentView.bounds;
            CGMutablePathRef path = [self createRoundedPathWithBounds:bounds cornerRadius:cornerRadius];
    
            maskLayer.path = path;
    
            // Apply the mask to the window's content view layer
            contentLayer.mask = maskLayer;
    
            // Create a border layer
            CAShapeLayer *borderLayer = [CAShapeLayer layer];
            borderLayer.path = path;
            borderLayer.fillColor = [NSColor clearColor].CGColor;
            borderLayer.strokeColor = [NSColor whiteColor].CGColor;
            borderLayer.lineWidth = borderWidth;
            borderLayer.frame = bounds;
    
            // Add the border layer above the content layer
            [contentLayer addSublayer:borderLayer];
    
            // Associate the border layer for future reference
            objc_setAssociatedObject(self, "borderLayer", borderLayer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
            // Create an outline layer
            CAShapeLayer *outlineLayer = [CAShapeLayer layer];
            outlineLayer.path = path;
            outlineLayer.fillColor = [NSColor clearColor].CGColor;
            outlineLayer.strokeColor = [NSColor darkGrayColor].CGColor;
            outlineLayer.lineWidth = borderWidth;
            outlineLayer.frame = bounds;
    
            // Disable animations for the outline layer
            outlineLayer.actions = @{
              @"strokeColor" : [NSNull null],
              @"lineWidth" : [NSNull null],
              @"path" : [NSNull null]
            };
    
            // Add the outline layer as the top-most layer
            [contentLayer addSublayer:outlineLayer];
    
            // Store the outline layer for later updates
            objc_setAssociatedObject(self, "outlineLayer", outlineLayer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
            CGPathRelease(path);
    
            // Modify window properties
            window.opaque = NO;
            window.backgroundColor = [NSColor clearColor];
            window.hasShadow = YES;
    
            // Set window to have a full-size content view
            window.styleMask |= NSWindowStyleMaskFullSizeContentView;
    
            // Remove title bar
            window.titlebarAppearsTransparent = YES;
            window.titleVisibility = NSWindowTitleHidden;
    
            // Make sure the window can still be moved
            window.movableByWindowBackground = YES;
    
            // Set up notifications for active/inactive state and resizing
            [[NSNotificationCenter defaultCenter]
                addObserver:self
                   selector:@selector(windowDidResignKey:)
                       name:NSWindowDidResignKeyNotification
                     object:window];
            [[NSNotificationCenter defaultCenter]
                addObserver:self
                   selector:@selector(windowDidBecomeKey:)
                       name:NSWindowDidBecomeKeyNotification
                     object:window];
            [[NSNotificationCenter defaultCenter]
                addObserver:self
                   selector:@selector(windowDidResize:)
                       name:NSWindowDidResizeNotification
                     object:window];
            [[NSNotificationCenter defaultCenter]
                addObserver:self
                   selector:@selector(windowWillStartLiveResize:)
                       name:NSWindowWillStartLiveResizeNotification
                     object:window];
            [[NSNotificationCenter defaultCenter]
                addObserver:self
                   selector:@selector(windowDidEndLiveResize:)
                       name:NSWindowDidEndLiveResizeNotification
                     object:window];
    
            // Initial update of border color
            [self updateBorderColorForWindow:window];
        } else {
            DLog("Failed to add window borders: contentView.layer is nil");
        }
    }
    
    /**
     * Updates the mask and outline layers for the window based on its bounds.
     * This method ensures the contentView is layer-backed, creates or updates
     * the mask and outline layers, and sets their paths and properties.
     *
     * @param window The window whose mask and outline layers need to be updated.
     */
    - (void)updateMaskAndOutlineForWindow:(NSWindow *)window {
        if (!enableWindowBorders) {
            return;
        }
    
        CALayer *contentLayer = window.contentView.layer;
        CGFloat cornerRadius = 40.0;
    
        // Retrieve existing outline layer
        CAShapeLayer *outlineLayer = objc_getAssociatedObject(self, "outlineLayer");
        CAShapeLayer *borderLayer = objc_getAssociatedObject(self, "borderLayer");
        
        if (!outlineLayer || !borderLayer) {
            // If layers don't exist, re-add window borders
            [self addWindowBorders];
            return;
        }
    
        // Update mask layer
        CAShapeLayer *maskLayer = (CAShapeLayer *)contentLayer.mask;
        if (maskLayer) {
            CGRect bounds = window.contentView.bounds;
            CGMutablePathRef path = [self createRoundedPathWithBounds:bounds cornerRadius:cornerRadius];
            maskLayer.path = path;
            borderLayer.path = path;
            outlineLayer.path = path;
            borderLayer.frame = bounds;
            outlineLayer.frame = bounds;
            CGPathRelease(path);
        }
    
        // Update outline layer properties
        outlineLayer.strokeColor = window.isKeyWindow ? [NSColor whiteColor].CGColor : [NSColor darkGrayColor].CGColor;
    }
    
    /**
     * Updates the border color of the window based on its key state.
     * If the window is the key window, the border color is set to white.
     * Otherwise, it is set to dark gray.
     *
     * @param window The window whose border color needs to be updated.
     */
    - (void)updateBorderColorForWindow:(NSWindow *)window {
        if (!enableWindowBorders) {
            return;
        }
    
        CAShapeLayer *outlineLayer = objc_getAssociatedObject(self, "outlineLayer");
        if (!outlineLayer) {
            // If outlineLayer doesn't exist, re-add window borders
            [self addWindowBorders];
            return;
        }
    
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        outlineLayer.strokeColor = window.isKeyWindow ? [NSColor whiteColor].CGColor : [NSColor darkGrayColor].CGColor;
        [CATransaction commit];
    }
    
    
    #pragma mark - Notification Handlers
    
    - (void)windowDidResignKey:(NSNotification *)notification {
        if (!enableWindowBorders) {
            return;
        }
    
        NSWindow *window = (NSWindow *)self;
        [self updateBorderColorForWindow:window];
    }
    
    - (void)windowDidBecomeKey:(NSNotification *)notification {
        if (!enableWindowBorders) {
            return;
        }
    
        NSWindow *window = (NSWindow *)self;
        [self updateBorderColorForWindow:window];
    }
    
    - (void)windowWillStartLiveResize:(NSNotification *)notification {
        if (!enableWindowBorders) {
            return;
        }
    
        NSWindow *window = (NSWindow *)self;
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        [self updateMaskAndOutlineForWindow:window];
        [CATransaction commit];
    }
    
    - (void)windowDidResize:(NSNotification *)notification {
        if (!enableWindowBorders) {
            return;
        }
    
        NSWindow *window = (NSWindow *)self;
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        [self updateMaskAndOutlineForWindow:window];
        [CATransaction commit];
    }
    
    - (void)windowDidEndLiveResize:(NSNotification *)notification {
        if (!enableWindowBorders) {
            return;
        }
    
        NSWindow *window = (NSWindow *)self;
        [self updateBorderColorForWindow:window];
        [self modifyTitlebarAppearance];
        [window.contentView setNeedsDisplay:YES];
        [window display];
    }
    
    @end
