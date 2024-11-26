//
//  macwmfx.m
//  macwmfx
//
//  Created by Alex "aspauldingcode" on 11/13/24.
//  Copyright (c) 2024 Alex "aspauldingcode". All rights reserved.
//

    #import <AppKit/AppKit.h>
    #import <QuartzCore/QuartzCore.h>
    #import "NSWindow+macwmfx.h"
    #import "ZKSwizzle.h"
    #import <objc/runtime.h>
    #import <os/log.h>

    #define DLog(N, ...) \
        os_log_with_type(os_log_create("com.aspauldingcode.macwmfx", "DEBUG"), \
                        OS_LOG_TYPE_DEFAULT, N, ##__VA_ARGS__)

    #pragma mark - Global Constants

    static NSString * const PreferencesSuiteName = @"com.aspauldingcode.macwmfx";
    static NSString * const ConfigFilePath = @".config/macwmfx/config";

    #pragma mark - macwmfx Interface

    @interface macwmfx ()

    @property (nonatomic, strong) NSDictionary *config;
    @property (nonatomic, assign) BOOL enableTrafficLightsDisabler;
    @property (nonatomic, assign) BOOL enableTitlebarDisabler;
    @property (nonatomic, assign) BOOL enableResizability;
    @property (nonatomic, assign) BOOL enableWindowBorders;

    + (instancetype)sharedInstance;
    - (void)initializeFeatureFlags;
    + (NSDictionary *)loadConfig;

    @end

    #pragma mark - macwmfx Implementation

    @implementation macwmfx

    + (instancetype)sharedInstance {
        static macwmfx *sharedInstance = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            sharedInstance = [[macwmfx alloc] init];
            [sharedInstance initializeFeatureFlags];
        });
        return sharedInstance;
    }

    + (void)load {
        [self sharedInstance];
    }

    - (void)initializeFeatureFlags {
        self.config = [[self class] loadConfig];
        self.enableTrafficLightsDisabler = [self.config[@"disableTrafficLights"] boolValue];
        self.enableTitlebarDisabler = [self.config[@"disableTitlebar"] boolValue];
        self.enableResizability = [self.config[@"disableWindowSizeConstraints"] boolValue];
        self.enableWindowBorders = [self.config[@"outlineWindow"][@"enabled"] boolValue];
    }

    + (NSDictionary *)loadConfig {
        NSString *configPath = [NSString stringWithFormat:@"%@/%@", NSHomeDirectory(), ConfigFilePath];
        NSData *configData = [NSData dataWithContentsOfFile:configPath];
        if (configData) {
            NSError *error = nil;
            NSDictionary *config = [NSJSONSerialization JSONObjectWithData:configData options:0 error:&error];
            if (error) {
                DLog("Error parsing config file: %@", error);
                return @{};
            }
            return config;
        }
        DLog("Config file not found at path: %@", configPath);
        return @{};
    }

    @end

    #pragma mark - NSWindow Swizzling

    ZKSwizzleInterface(BS_NSWindow, NSWindow, NSWindow)

    @interface BS_NSWindow ()

    - (void)hideTrafficLights;
    - (void)hideButton:(NSButton *)button;
    - (void)modifyTitlebarAppearance;
    - (void)makeResizableToAnySize;
    - (void)addWindowBorders;
    - (CGFloat)cornerRadiusFromConfig:(NSDictionary *)config;
    - (CGFloat)borderWidthFromConfig:(NSDictionary *)config;
    - (NSColor *)activeColorFromConfig:(NSDictionary *)config;
    - (NSColor *)inactiveColorFromConfig:(NSDictionary *)config;
    - (NSColor *)colorFromHexString:(NSString *)hexString;
    - (CGMutablePathRef)createRoundedPathWithBounds:(CGRect)bounds cornerRadius:(CGFloat)cornerRadius;
    - (void)removeExistingLayersFromContentLayer:(CALayer *)contentLayer;
    - (void)setupNotificationObserversForWindow:(NSWindow *)window;
    - (void)updateMaskAndOutlineForWindow:(NSWindow *)window;
    - (void)updateBorderColorForWindow:(NSWindow *)window;
    - (void)windowDidResignKey:(NSNotification *)notification;
    - (void)windowDidBecomeKey:(NSNotification *)notification;
    - (void)windowWillStartLiveResize:(NSNotification *)notification;
    - (void)windowDidResize:(NSNotification *)notification;
    - (void)windowDidEndLiveResize:(NSNotification *)notification;

    @end

    @implementation BS_NSWindow

    #pragma mark - Overridden Methods

    - (nullable NSButton *)standardWindowButton:(NSWindowButton)button {
        return ZKOrig(NSButton *, button);
    }

    - (void)makeKeyAndOrderFront:(id)sender {
        ZKOrig(void, sender);
        
        macwmfx *sharedInstance = [macwmfx sharedInstance];
        
        if (sharedInstance.enableTitlebarDisabler) {
            [self modifyTitlebarAppearance];
        }
        
        if (sharedInstance.enableTrafficLightsDisabler) {
            [self hideTrafficLights];
        }
        
        if (sharedInstance.enableResizability) {
            [self makeResizableToAnySize];
        }
        
        if (sharedInstance.enableWindowBorders) {
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
        
        macwmfx *sharedInstance = [macwmfx sharedInstance];
        if (!sharedInstance.enableWindowBorders) {
            return;
        }
        
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        [self updateMaskAndOutlineForWindow:self];
        [CATransaction commit];
        
        [self updateBorderColorForWindow:self];
        [self modifyTitlebarAppearance];
        [self display];
    }

    #pragma mark - Custom Methods

    - (void)hideTrafficLights {
        [self hideButton:[self standardWindowButton:NSWindowCloseButton]];
        [self hideButton:[self standardWindowButton:NSWindowMiniaturizeButton]];
        [self hideButton:[self standardWindowButton:NSWindowZoomButton]];
    }

    - (void)hideButton:(NSButton *)button {
        if (button) {
            button.hidden = YES;
        }
    }

    - (void)modifyTitlebarAppearance {
        self.titlebarAppearsTransparent = YES;
        self.titleVisibility = NSWindowTitleHidden;
        self.styleMask |= NSWindowStyleMaskFullSizeContentView;
        self.contentView.wantsLayer = YES; // Ensure contentView is layer-backed
    }

    - (void)makeResizableToAnySize {
        self.styleMask |= NSWindowStyleMaskResizable;
        [self setMinSize:NSMakeSize(0.0, 0.0)];
        [self setMaxSize:NSMakeSize(CGFLOAT_MAX, CGFLOAT_MAX)];
    }

    #pragma mark - Window Border Methods

    - (CGFloat)cornerRadiusFromConfig:(NSDictionary *)config {
        NSNumber *cornerRadius = config[@"outlineWindow"][@"cornerRadius"];
        return cornerRadius ? cornerRadius.floatValue : 0.0;
    }

    - (CGFloat)borderWidthFromConfig:(NSDictionary *)config {
        NSNumber *width = config[@"outlineWindow"][@"width"];
        return width ? width.floatValue : 2.0;
    }

    - (NSColor *)activeColorFromConfig:(NSDictionary *)config {
        NSString *activeColorString = config[@"outlineWindow"][@"activeColor"];
        return (activeColorString.length > 0) ? [self colorFromHexString:activeColorString] : [NSColor whiteColor];
    }

    - (NSColor *)inactiveColorFromConfig:(NSDictionary *)config {
        NSString *inactiveColorString = config[@"outlineWindow"][@"inactiveColor"];
        return (inactiveColorString.length > 0) ? [self colorFromHexString:inactiveColorString] : [NSColor darkGrayColor];
    }

    - (NSColor *)colorFromHexString:(NSString *)hexString {
        unsigned rgbValue = 0;
        NSScanner *scanner = [NSScanner scannerWithString:hexString];
        NSCharacterSet *hexSet = [NSCharacterSet characterSetWithCharactersInString:@"0123456789ABCDEFabcdef"];
        // Ensure scanner only scans hex digits
        if (![hexSet isSupersetOfSet:[NSCharacterSet characterSetWithCharactersInString:hexString]]) {
            DLog("Invalid hex string: %@", hexString);
            return [NSColor clearColor];
        }
        [scanner setScanLocation:0];
        [scanner scanHexInt:&rgbValue];
        
        CGFloat red = ((rgbValue & 0xFF0000) >> 16)/255.0;
        CGFloat green = ((rgbValue & 0x00FF00) >> 8)/255.0;
        CGFloat blue = (rgbValue & 0x0000FF)/255.0;
        
        return [NSColor colorWithRed:red green:green blue:blue alpha:1.0];
    }

    - (CGMutablePathRef)createRoundedPathWithBounds:(CGRect)bounds cornerRadius:(CGFloat)cornerRadius {
        CGMutablePathRef path = CGPathCreateMutable();
        
        // Create a rounded rectangle path
        CGPathAddRoundedRect(path, NULL, bounds, cornerRadius, cornerRadius);
        
        return path;
    }

    - (void)addWindowBorders {
        macwmfx *sharedInstance = [macwmfx sharedInstance];
        if (!sharedInstance.enableWindowBorders) {
            return;
        }
        
        NSDictionary *config = sharedInstance.config;
        CGFloat borderWidth = [self borderWidthFromConfig:config];
        CGFloat cornerRadius = [self cornerRadiusFromConfig:config];
        NSColor *activeColor = [self activeColorFromConfig:config];
        NSColor *inactiveColor = [self inactiveColorFromConfig:config];
        
        // Ensure the contentView is layer-backed
        self.contentView.wantsLayer = YES;
        CALayer *contentLayer = self.contentView.layer;
        
        if (contentLayer) {
            // Remove existing layers if any
            [self removeExistingLayersFromContentLayer:contentLayer];
            
            // Create mask layer
            CAShapeLayer *maskLayer = [CAShapeLayer layer];
            CGRect bounds = self.contentView.bounds;
            CGMutablePathRef path = [self createRoundedPathWithBounds:bounds cornerRadius:cornerRadius];
            maskLayer.path = path;
            contentLayer.mask = maskLayer;
            CGPathRelease(path);
            
            // Create border layer
            CAShapeLayer *borderLayer = [CAShapeLayer layer];
            borderLayer.path = maskLayer.path;
            borderLayer.fillColor = [NSColor clearColor].CGColor;
            borderLayer.strokeColor = activeColor.CGColor;
            borderLayer.lineWidth = borderWidth;
            borderLayer.frame = bounds;
            [contentLayer addSublayer:borderLayer];
            objc_setAssociatedObject(self, "borderLayer", borderLayer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            
            // Create outline layer
            CAShapeLayer *outlineLayer = [CAShapeLayer layer];
            outlineLayer.path = maskLayer.path;
            outlineLayer.fillColor = [NSColor clearColor].CGColor;
            outlineLayer.strokeColor = inactiveColor.CGColor;
            outlineLayer.lineWidth = borderWidth;
            outlineLayer.frame = bounds;
            // Disable implicit animations
            outlineLayer.actions = @{
                @"strokeColor" : [NSNull null],
                @"lineWidth" : [NSNull null],
                @"path" : [NSNull null]
            };
            [contentLayer addSublayer:outlineLayer];
            objc_setAssociatedObject(self, "outlineLayer", outlineLayer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            
            // Modify window properties
            self.opaque = NO;
            self.backgroundColor = [NSColor clearColor];
            self.hasShadow = NO;
            self.styleMask |= NSWindowStyleMaskFullSizeContentView;
            self.titlebarAppearsTransparent = YES;
            self.titleVisibility = NSWindowTitleHidden;
            
            // Setup observers
            [self setupNotificationObserversForWindow:self];
            
            // Initial border color update
            [self updateBorderColorForWindow:self];
        } else {
            DLog("Failed to add window borders: contentView.layer is nil");
        }
    }

    - (void)removeExistingLayersFromContentLayer:(CALayer *)contentLayer {
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
    }

    - (void)setupNotificationObserversForWindow:(NSWindow *)window {
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        
        [center addObserver:self selector:@selector(windowDidResignKey:) name:NSWindowDidResignKeyNotification object:window];
        [center addObserver:self selector:@selector(windowDidBecomeKey:) name:NSWindowDidBecomeKeyNotification object:window];
        [center addObserver:self selector:@selector(windowDidResize:) name:NSWindowDidResizeNotification object:window];
        [center addObserver:self selector:@selector(windowWillStartLiveResize:) name:NSWindowWillStartLiveResizeNotification object:window];
        [center addObserver:self selector:@selector(windowDidEndLiveResize:) name:NSWindowDidEndLiveResizeNotification object:window];
    }

    - (void)updateMaskAndOutlineForWindow:(NSWindow *)window {
        macwmfx *sharedInstance = [macwmfx sharedInstance];
        if (!sharedInstance.enableWindowBorders) {
            return;
        }
        
        NSDictionary *config = sharedInstance.config;
        CGFloat cornerRadius = [self cornerRadiusFromConfig:config];
        CGFloat borderWidth = [self borderWidthFromConfig:config];
        
        CAShapeLayer *maskLayer = (CAShapeLayer *)window.contentView.layer.mask;
        if (maskLayer) {
            CGRect bounds = window.contentView.bounds;
            CGMutablePathRef newPath = [self createRoundedPathWithBounds:bounds cornerRadius:cornerRadius];
            maskLayer.path = newPath;
            
            CAShapeLayer *borderLayer = objc_getAssociatedObject(self, "borderLayer");
            CAShapeLayer *outlineLayer = objc_getAssociatedObject(self, "outlineLayer");
            
            borderLayer.path = newPath;
            borderLayer.frame = bounds;
            borderLayer.lineWidth = borderWidth;
            
            outlineLayer.path = newPath;
            outlineLayer.frame = bounds;
            outlineLayer.lineWidth = borderWidth;
            
            CGPathRelease(newPath);
        }
        
        [self updateBorderColorForWindow:window];
    }

    - (void)updateBorderColorForWindow:(NSWindow *)window {
        macwmfx *sharedInstance = [macwmfx sharedInstance];
        if (!sharedInstance.enableWindowBorders) {
            return;
        }
        
        NSDictionary *config = sharedInstance.config;
        NSColor *activeColor = [self activeColorFromConfig:config];
        NSColor *inactiveColor = [self inactiveColorFromConfig:config];
        
        CAShapeLayer *outlineLayer = objc_getAssociatedObject(self, "outlineLayer");
        if (!outlineLayer) {
            [self addWindowBorders];
            return;
        }
        
        NSColor *strokeColor = window.isKeyWindow ? activeColor : inactiveColor;
        outlineLayer.strokeColor = strokeColor.CGColor;
    }

    #pragma mark - Notification Handlers

    - (void)windowDidResignKey:(NSNotification *)notification {
        [self updateBorderColorForWindow:self];
    }

    - (void)windowDidBecomeKey:(NSNotification *)notification {
        [self updateBorderColorForWindow:self];
    }

    - (void)windowWillStartLiveResize:(NSNotification *)notification {
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        [self updateMaskAndOutlineForWindow:self];
        [CATransaction commit];
    }

    - (void)windowDidResize:(NSNotification *)notification {
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        [self updateMaskAndOutlineForWindow:self];
        [CATransaction commit];
    }

    - (void)windowDidEndLiveResize:(NSNotification *)notification {
        [self updateBorderColorForWindow:self];
        [self modifyTitlebarAppearance];
        [self.contentView setNeedsDisplay:YES];
        [self display];
    }

    #pragma mark - Cleanup

    - (void)dealloc {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }

    @end
