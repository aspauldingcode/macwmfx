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
static BOOL enableTrafficLightsDisabler;
static BOOL enableTitlebarDisabler;
static BOOL enableResizability;
static BOOL enableWindowBorders;

#pragma mark - Main Implementation

@interface StopStoplightLight ()

+ (NSDictionary *)loadConfig;

@end

@implementation StopStoplightLight

+ (instancetype)sharedInstance {
  static StopStoplightLight *sharedInstance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedInstance = [[self alloc] init];
    [sharedInstance initializeFeatureFlags];
  });
  return sharedInstance;
}

+ (void)load {
  [self sharedInstance];
}

- (void)initializeFeatureFlags {
    NSDictionary *config = [[self class] loadConfig];
    enableTrafficLightsDisabler = [config[@"disableTrafficLights"] boolValue];
    enableTitlebarDisabler = [config[@"disableTitlebar"] boolValue];
    enableResizability = [config[@"disableWindowSizeConstraints"] boolValue];
    enableWindowBorders = [config[@"outlineWindow"][@"enabled"] boolValue];
}

+ (NSDictionary *)loadConfig {
    NSString *configPath = [NSString stringWithFormat:@"%@/.config/macwmfx/config", NSHomeDirectory()];
    NSData *configData = [NSData dataWithContentsOfFile:configPath];
    if (configData) {
        NSError *error;
        NSDictionary *config = [NSJSONSerialization JSONObjectWithData:configData options:0 error:&error];
        if (error) {
            DLog("Error parsing config file: %@", error);
            return @{};
        }
        return config;
    }
    return @{};
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

// delete built-in mask without using PaintCan plugin
// FIXME: THIS IS NOT IMPLEMENTED YET

- (CGFloat)cornerRadiusFromConfig:(NSDictionary *)config {
    NSNumber *cornerRadius = config[@"outlineWindow"][@"cornerRadius"];
    return cornerRadius ? [cornerRadius floatValue] : 0.0;
}

- (CGFloat)borderWidthFromConfig:(NSDictionary *)config {
    NSNumber *width = config[@"outlineWindow"][@"width"];
    return width ? [width floatValue] : 2.0;
}

- (NSColor *)activeColorFromConfig:(NSDictionary *)config {
    NSString *activeColorString = config[@"outlineWindow"][@"activeColor"];
    return activeColorString.length > 0 ? [self colorFromHexString:activeColorString] : [NSColor whiteColor];
}

- (NSColor *)inactiveColorFromConfig:(NSDictionary *)config {
    NSString *inactiveColorString = config[@"outlineWindow"][@"inactiveColor"];
    return inactiveColorString.length > 0 ? [self colorFromHexString:inactiveColorString] : [NSColor darkGrayColor];
}

- (NSColor *)colorFromHexString:(NSString *)hexString {
    unsigned rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    [scanner setScanLocation:0];
    [scanner scanHexInt:&rgbValue];
    return [NSColor colorWithRed:((rgbValue & 0xFF0000) >> 16) / 255.0
                           green:((rgbValue & 0x00FF00) >> 8) / 255.0
                            blue:(rgbValue & 0x0000FF) / 255.0
                           alpha:1.0];
}

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

- (void)addWindowBorders {
    if (!enableWindowBorders) {
        return;
    }

    NSDictionary *config = [StopStoplightLight loadConfig];
    CGFloat borderWidth = [self borderWidthFromConfig:config];
    CGFloat cornerRadius = [self cornerRadiusFromConfig:config];
    NSColor *activeColor = [self activeColorFromConfig:config];
    NSColor *inactiveColor = [self inactiveColorFromConfig:config];

    NSWindow *window = (NSWindow *)self;

    // Ensure the contentView is layer-backed
    window.contentView.wantsLayer = YES;

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
        borderLayer.strokeColor = activeColor.CGColor;
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
        outlineLayer.strokeColor = inactiveColor.CGColor;
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
        window.hasShadow = NO;

        // Set window to have a full-size content view
        window.styleMask |= NSWindowStyleMaskFullSizeContentView;

        // Remove title bar
        window.titlebarAppearsTransparent = YES;
        window.titleVisibility = NSWindowTitleHidden;

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

- (void)updateMaskAndOutlineForWindow:(NSWindow *)window {
    if (!enableWindowBorders) {
        return;
    }

    NSDictionary *config = [StopStoplightLight loadConfig];
    CGFloat cornerRadius = [self cornerRadiusFromConfig:config];
    CGFloat borderWidth = [self borderWidthFromConfig:config];

    CALayer *contentLayer = window.contentView.layer;

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
        borderLayer.lineWidth = borderWidth;
        outlineLayer.lineWidth = borderWidth;
        CGPathRelease(path);
    }

    // Update outline layer properties
    NSColor *activeColor = [self activeColorFromConfig:config];
    NSColor *inactiveColor = [self inactiveColorFromConfig:config];
    outlineLayer.strokeColor = window.isKeyWindow ? activeColor.CGColor : inactiveColor.CGColor;
}

- (void)updateBorderColorForWindow:(NSWindow *)window {
    if (!enableWindowBorders) {
        return;
    }

    NSDictionary *config = [StopStoplightLight loadConfig];
    NSColor *activeColor = [self activeColorFromConfig:config];
    NSColor *inactiveColor = [self inactiveColorFromConfig:config];

    CAShapeLayer *outlineLayer = objc_getAssociatedObject(self, "outlineLayer");
    if (!outlineLayer) {
        // If outlineLayer doesn't exist, re-add window borders
        [self addWindowBorders];
        return;
    }

    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    outlineLayer.strokeColor = window.isKeyWindow ? activeColor.CGColor : inactiveColor.CGColor;
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
