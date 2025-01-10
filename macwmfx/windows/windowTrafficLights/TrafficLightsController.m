//
//  TrafficLightsController.m
//  macwmfx
//
//  Created by Alex "aspauldingcode" on 01/10/25.
//  Copyright (c) 2025 Alex "aspauldingcode". All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import "../../headers/macwmfx_globals.h"

@interface TrafficLightsController : NSObject {
    BOOL _isUpdating;
    BOOL _isFullPositionUpdate;
    NSMutableDictionary *_windowPositions;
    NSMutableDictionary *_trackingAreas;
}
@end

@implementation TrafficLightsController

+ (instancetype)sharedInstance {
    static TrafficLightsController *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _isUpdating = NO;
        _isFullPositionUpdate = NO;
        _windowPositions = [NSMutableDictionary new];
        _trackingAreas = [NSMutableDictionary new];
        [[NSDistributedNotificationCenter defaultCenter] addObserver:self
                                                         selector:@selector(handleConfigChange:)
                                                             name:@"com.macwmfx.configChanged"
                                                           object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
}

- (void)handleConfigChange:(NSNotification *)notification {
    @try {
        if (_isUpdating) return;
        
        _isUpdating = YES;
        _isFullPositionUpdate = YES;  // Only update positions on config changes
        [_windowPositions removeAllObjects];  // Clear cached positions on config change
        
        for (NSWindow *window in [NSApp windows]) {
            if ([window isKindOfClass:[NSWindow class]] && (window.styleMask & NSWindowStyleMaskTitled)) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self updateTrafficLights:window];
                });
            }
        }
        
        _isUpdating = NO;
        _isFullPositionUpdate = NO;
    } @catch (NSException *e) {
        _isUpdating = NO;
        _isFullPositionUpdate = NO;
        NSLog(@"[macwmfx] Error in handleConfigChange: %@ - %@", e.name, e.reason);
    }
}

- (void)safelySetLayer:(NSButton *)button {
    if (!button || button.layer) return;
    button.wantsLayer = YES;
}

// Windows style traffic lights:
// The trafficlights buttons in windows style need to have no background. 
// and, when the window is inactive, the traffic lights icons need to be gray (in light mode and darkmode).
// When the window is active, the traffic lights icons need to be black in lightmode, white in darkmode, The background on hover needs to be mostly transparent.
// on hover, the max/min buttons need to have light gray background in lightmode, and dark gray in darkmode. The background on hover needs to be mostly transparent.
// on hover, the close button needs to have white icon with red background, in lightmode and in darkmode. The background on hover needs to be opaque.

- (void)drawWindowsStyleSymbol:(NSButton *)button type:(NSWindowButton)buttonType {
    @try {
        if (!button || !button.window) {
            NSLog(@"[macwmfx] Warning: Invalid button in drawWindowsStyleSymbol");
            return;
        }
        
        // Ensure we have a valid layer
        [self safelySetLayer:button];
        if (!button.layer) {
            NSLog(@"[macwmfx] Warning: Failed to create layer for button");
            return;
        }
        
        // Get or create the container layer safely
        CALayer *containerLayer = nil;
        for (CALayer *layer in button.layer.sublayers) {
            if ([layer.name isEqualToString:@"WindowsStyleContainer"]) {
                containerLayer = layer;
                break;
            }
        }
        
        if (!containerLayer) {
            containerLayer = [CALayer layer];
            containerLayer.name = @"WindowsStyleContainer";
            [button.layer addSublayer:containerLayer];
        }
        
        // Create the path for the symbol
        NSBezierPath *path = [NSBezierPath bezierPath];
        path.lineWidth = 1.5;
        
        // Use default size logic
        CGFloat defaultSize = [gTrafficLightsConfig.style isEqualToString:@"windows"] ? 16.0 : 12.0;
        CGFloat buttonSize = gTrafficLightsConfig.size > 0 ? gTrafficLightsConfig.size : defaultSize;
        
        // Adjust padding based on button size
        CGFloat padding = buttonSize * 0.25;
        
        NSRect bounds = NSMakeRect(0, 0, buttonSize, buttonSize);
        containerLayer.frame = bounds;
        button.frame = bounds;
        
        // Draw the symbol paths
        if (buttonType == NSWindowCloseButton) {
            [path moveToPoint:NSMakePoint(padding, padding)];
            [path lineToPoint:NSMakePoint(NSWidth(bounds) - padding, NSHeight(bounds) - padding)];
            [path moveToPoint:NSMakePoint(NSWidth(bounds) - padding, padding)];
            [path lineToPoint:NSMakePoint(padding, NSHeight(bounds) - padding)];
        } 
        else if (buttonType == NSWindowZoomButton) {
            [path moveToPoint:NSMakePoint(padding, padding)];
            [path lineToPoint:NSMakePoint(NSWidth(bounds) - padding, padding)];
            [path lineToPoint:NSMakePoint(NSWidth(bounds) - padding, NSHeight(bounds) - padding)];
            [path lineToPoint:NSMakePoint(padding, NSHeight(bounds) - padding)];
            [path closePath];
        }
        else if (buttonType == NSWindowMiniaturizeButton) {
            CGFloat yPos = NSHeight(bounds) / 2;
            [path moveToPoint:NSMakePoint(padding, yPos)];
            [path lineToPoint:NSMakePoint(NSWidth(bounds) - padding, yPos)];
        }
        
        // Convert NSBezierPath to CGPath safely
        CGPathRef cgPath = NULL;
        NSInteger numElements = [path elementCount];
        if (numElements > 0) {
            CGMutablePathRef mutablePath = CGPathCreateMutable();
            NSPoint points[3];
            
            @try {
                for (NSInteger i = 0; i < numElements; i++) {
                    NSBezierPathElement element = [path elementAtIndex:i associatedPoints:points];
                    switch(element) {
                        case NSBezierPathElementMoveTo:
                            CGPathMoveToPoint(mutablePath, NULL, points[0].x, points[0].y);
                            break;
                        case NSBezierPathElementLineTo:
                            CGPathAddLineToPoint(mutablePath, NULL, points[0].x, points[0].y);
                            break;
                        case NSBezierPathElementClosePath:
                            CGPathCloseSubpath(mutablePath);
                            break;
                        default:
                            break;
                    }
                }
                
                cgPath = CGPathCreateCopy(mutablePath);
            } @finally {
                CGPathRelease(mutablePath);
            }
            
            if (cgPath) {
                @try {
                    // Update existing symbol layer if it exists, otherwise create new one
                    CAShapeLayer *symbolLayer = nil;
                    for (CALayer *layer in containerLayer.sublayers) {
                        if ([layer.name isEqualToString:@"WindowsStyleSymbol"] && [layer isKindOfClass:[CAShapeLayer class]]) {
                            symbolLayer = (CAShapeLayer *)layer;
                            break;
                        }
                    }
                    
                    if (!symbolLayer) {
                        symbolLayer = [CAShapeLayer layer];
                        symbolLayer.name = @"WindowsStyleSymbol";
                        [containerLayer addSublayer:symbolLayer];
                    }
                    
                    symbolLayer.path = cgPath;
                    symbolLayer.fillColor = nil;
                    symbolLayer.lineWidth = 1.5;
                    
                    // Set colors based on window state and appearance
                    BOOL isDark = NO;
                    if (@available(macOS 10.14, *)) {
                        isDark = [NSApp.effectiveAppearance bestMatchFromAppearancesWithNames:@[NSAppearanceNameDarkAqua, NSAppearanceNameAqua]] == NSAppearanceNameDarkAqua;
                    }
                    
                    BOOL isActive = button.window.isKeyWindow;
                    symbolLayer.strokeColor = isActive ? 
                        (isDark ? [NSColor whiteColor].CGColor : [NSColor blackColor].CGColor) :
                        [NSColor grayColor].CGColor;
                    
                } @finally {
                    CGPathRelease(cgPath);
                }
            }
        }
        
    } @catch (NSException *e) {
        NSLog(@"[macwmfx] Error in drawWindowsStyleSymbol: %@ - %@", e.name, e.reason);
    }
}

- (void)applyStyle:(NSButton *)closeButton minimizeButton:(NSButton *)minimizeButton zoomButton:(NSButton *)zoomButton window:(NSWindow *)window {
    BOOL isWindowsStyle = [gTrafficLightsConfig.style isEqualToString:@"windows"];
    
    if (isWindowsStyle) {
        for (NSButton *button in @[closeButton, minimizeButton, zoomButton]) {
            // Basic button setup
            button.wantsLayer = YES;
            [button setButtonType:NSButtonTypeMomentaryLight];
            [button setBordered:YES];
            [button setBezelStyle:NSBezelStyleFlexiblePush];
            
            // Clear background
            button.layer.backgroundColor = [NSColor clearColor].CGColor;
            
            // Set border
            button.layer.borderWidth = 1.0;
            button.layer.borderColor = [NSColor grayColor].CGColor;
        }
        
        // Apply Windows-style symbols
        [self drawWindowsStyleSymbol:closeButton type:NSWindowCloseButton];
        [self drawWindowsStyleSymbol:minimizeButton type:NSWindowMiniaturizeButton];
        [self drawWindowsStyleSymbol:zoomButton type:NSWindowZoomButton];
    } else if ([gTrafficLightsConfig.style isEqualToString:@"flat"]) {
        for (NSButton *button in @[closeButton, minimizeButton, zoomButton]) {
            button.layer.borderWidth = 0;
            [button setBordered:NO];
            [button setBezelStyle:NSBezelStyleTexturedSquare];
        }
    } else {
        // Default macOS style
        for (NSButton *button in @[closeButton, minimizeButton, zoomButton]) {
            [self applyMacOSStyle:button];
        }
    }
}

- (void)applyMacOSStyle:(NSButton *)button {
    @try {
        if (!button) return;
        
        // Remove all Windows style layers
        [button.layer setSublayers:nil];
        
        // Reset button to default state
        [button setCell:[[NSButtonCell alloc] init]];
        [button setButtonType:NSButtonTypeMomentaryLight];
        [button setBordered:NO];
        [button setTransparent:NO];
        button.layer.backgroundColor = [NSColor clearColor].CGColor;
        
    } @catch (NSException *e) {
        NSLog(@"[macwmfx] Error in applyMacOSStyle: %@ - %@", e.name, e.reason);
    }
}

- (void)updateTrafficLights:(NSWindow *)window {
    @try {
        if (!window || !(window.styleMask & NSWindowStyleMaskTitled)) {
            return;
        }

        if (_isUpdating) {
            return;
        }

        _isUpdating = YES;

        // Get the traffic light buttons
        NSButton *closeButton = [window standardWindowButton:NSWindowCloseButton];
        NSButton *minimizeButton = [window standardWindowButton:NSWindowMiniaturizeButton];
        NSButton *zoomButton = [window standardWindowButton:NSWindowZoomButton];

        if (!closeButton || !minimizeButton || !zoomButton) {
            _isUpdating = NO;
            return;
        }

        // Handle visibility first
        BOOL shouldHide = !gTrafficLightsConfig.enabled;
        for (NSButton *button in @[closeButton, minimizeButton, zoomButton]) {
            [button setHidden:shouldHide];
        }

        if (shouldHide) {
            _isUpdating = NO;
            return;
        }

        // Setup basic properties for all buttons
        for (NSButton *button in @[closeButton, minimizeButton, zoomButton]) {
            button.wantsLayer = YES;
            [button setButtonType:NSButtonTypeMomentaryLight];
            [button setBordered:NO];
            button.layer.borderWidth = 0;
            button.layer.borderColor = nil;
            button.layer.backgroundColor = nil;
        }

        // Apply shape first
        [self applyShape:closeButton minimizeButton:minimizeButton zoomButton:zoomButton];

        // Apply style (which includes Windows-style symbols if needed)
        [self applyStyle:closeButton minimizeButton:minimizeButton zoomButton:zoomButton window:window];

        // Apply colors (only if not Windows style)
        if (![gTrafficLightsConfig.style isEqualToString:@"windows"]) {
            [self applyColors:closeButton minimizeButton:minimizeButton zoomButton:zoomButton window:window];
        }

        // Apply position and order
        [self applyPositionAndOrder:closeButton minimizeButton:minimizeButton zoomButton:zoomButton window:window];

        // Setup tracking areas for hover effects
        [self setupTrackingAreas:closeButton minimizeButton:minimizeButton zoomButton:zoomButton window:window];

        // Set button actions
        for (NSButton *button in @[closeButton, minimizeButton, zoomButton]) {
            [button setTarget:self];
            [button setAction:@selector(handleButtonClick:)];
        }

        // Force update of button appearance
        for (NSButton *button in @[closeButton, minimizeButton, zoomButton]) {
            [button setNeedsDisplay:YES];
            for (CALayer *layer in button.layer.sublayers) {
                [layer setNeedsDisplay];
            }
        }

        _isUpdating = NO;
    } @catch (NSException *e) {
        _isUpdating = NO;
        NSLog(@"[macwmfx] Error in updateTrafficLights: %@ - %@", e.name, e.reason);
    }
}

- (void)applyShape:(NSButton *)closeButton minimizeButton:(NSButton *)minimizeButton zoomButton:(NSButton *)zoomButton {
    if (!gTrafficLightsConfig.shape) return;

    CGFloat cornerRadius = 0;
    CGFloat defaultSize = [gTrafficLightsConfig.style isEqualToString:@"windows"] ? 16.0 : 12.0;
    CGFloat buttonSize = gTrafficLightsConfig.size > 0 ? gTrafficLightsConfig.size : defaultSize;
    
    if ([gTrafficLightsConfig.shape isEqualToString:@"circle"]) {
        cornerRadius = buttonSize / 2.0;
    }

    for (NSButton *button in @[closeButton, minimizeButton, zoomButton]) {
        button.layer.cornerRadius = cornerRadius;
        button.layer.masksToBounds = YES;
    }
}

- (void)applyColors:(NSButton *)closeButton minimizeButton:(NSButton *)minimizeButton zoomButton:(NSButton *)zoomButton window:(NSWindow *)window {
    if (!gTrafficLightsConfig.customColor.enabled) return;

    ConfigParser *parser = [ConfigParser sharedInstance];
    BOOL isActive = window.isKeyWindow;
    TrafficLightsColorState *colorState = isActive ? 
        &gTrafficLightsConfig.customColor.active : 
        &gTrafficLightsConfig.customColor.inactive;

    if (colorState->stop) {
        closeButton.layer.backgroundColor = [parser colorFromHexString:colorState->stop].CGColor;
    }
    if (colorState->yield) {
        minimizeButton.layer.backgroundColor = [parser colorFromHexString:colorState->yield].CGColor;
    }
    if (colorState->go) {
        zoomButton.layer.backgroundColor = [parser colorFromHexString:colorState->go].CGColor;
    }
}

- (void)applyPositionAndOrder:(NSButton *)closeButton minimizeButton:(NSButton *)minimizeButton zoomButton:(NSButton *)zoomButton window:(NSWindow *)window {
    NSView *container = closeButton.superview;
    if (!container) return;

    CGFloat defaultSize = [gTrafficLightsConfig.style isEqualToString:@"windows"] ? 16.0 : 12.0;
    CGFloat buttonSize = gTrafficLightsConfig.size > 0 ? gTrafficLightsConfig.size : defaultSize;
    CGFloat defaultPadding = [gTrafficLightsConfig.style isEqualToString:@"windows"] ? 10.0 : 8.0;
    CGFloat padding = gTrafficLightsConfig.padding > 0 ? gTrafficLightsConfig.padding : defaultPadding;
    
    CGFloat xPos = padding;
    CGFloat yPos = window.frame.size.height - (([window contentLayoutRect].origin.y) / 2) - (buttonSize / 2);

    // Handle position (left/right)
    if ([gTrafficLightsConfig.position isEqualToString:@"top-right"]) {
        xPos = window.frame.size.width - ((buttonSize * 3) + (padding * 4));
    }

    // Handle order
    NSArray *orderParts = [gTrafficLightsConfig.order componentsSeparatedByString:@"-"];
    if (orderParts.count == 3) {
        NSDictionary *buttonMap = @{
            @"stop": closeButton,
            @"yield": minimizeButton,
            @"go": zoomButton
        };

        for (NSString *part in orderParts) {
            NSButton *button = buttonMap[part];
            if (button) {
                NSRect frame = button.frame;
                frame.origin.x = xPos;
                frame.origin.y = yPos;
                frame.size = NSMakeSize(buttonSize, buttonSize);
                button.frame = frame;
                xPos += buttonSize + padding;
            }
        }
    } else {
        // Default order
        NSArray *buttons = [gTrafficLightsConfig.style isEqualToString:@"windows"] ?
            @[minimizeButton, zoomButton, closeButton] :
            @[closeButton, minimizeButton, zoomButton];

        for (NSButton *button in buttons) {
            NSRect frame = button.frame;
            frame.origin.x = xPos;
            frame.origin.y = yPos;
            frame.size = NSMakeSize(buttonSize, buttonSize);
            button.frame = frame;
            xPos += buttonSize + padding;
        }
    }
}

- (void)setupTrackingAreas:(NSButton *)closeButton minimizeButton:(NSButton *)minimizeButton zoomButton:(NSButton *)zoomButton window:(NSWindow *)window {
    if (!window) return;
    
    NSString *windowKey = [NSString stringWithFormat:@"%p", window];
    
    // Remove existing tracking areas
    NSArray *existingAreas = _trackingAreas[windowKey];
    if (existingAreas) {
        for (NSTrackingArea *area in existingAreas) {
            if ([area.owner isKindOfClass:[NSButton class]]) {
                [(NSButton *)area.owner removeTrackingArea:area];
            }
        }
    }

    NSMutableArray *newAreas = [NSMutableArray array];
    
    for (NSButton *button in @[closeButton, minimizeButton, zoomButton]) {
        if (!button) continue;
        
        // Remove any existing tracking areas from the button
        for (NSTrackingArea *area in [button.trackingAreas copy]) {
            [button removeTrackingArea:area];
        }
        
        NSTrackingArea *area = [[NSTrackingArea alloc] initWithRect:button.bounds
                                                          options:(NSTrackingMouseEnteredAndExited | 
                                                                 NSTrackingActiveAlways |
                                                                 NSTrackingInVisibleRect)
                                                            owner:button
                                                         userInfo:nil];
        [button addTrackingArea:area];
        [newAreas addObject:area];
    }
    
    _trackingAreas[windowKey] = newAreas;
}

- (void)handleButtonHover:(NSButton *)button {
    @try {
        if (!button || !button.window) return;
        
        NSEvent *currentEvent = [NSApp currentEvent];
        if (!currentEvent) return;
        
        if (currentEvent.type == NSEventTypeMouseEntered) {
            [self handleMouseEntered:currentEvent forWindow:button.window];
        } else if (currentEvent.type == NSEventTypeMouseExited) {
            [self handleMouseExited:currentEvent forWindow:button.window];
        }
    } @catch (NSException *e) {
        NSLog(@"[macwmfx] Error in handleButtonHover: %@ - %@", e.name, e.reason);
    }
}

- (void)handleMouseEntered:(NSEvent *)event forWindow:(NSWindow *)window {
    @try {
        if (!gTrafficLightsConfig.enabled || !event || !window) return;
        
        NSButton *button = (NSButton *)event.trackingArea.owner;
        if (![button isKindOfClass:[NSButton class]]) return;
        
        BOOL isWindowsStyle = [gTrafficLightsConfig.style isEqualToString:@"windows"];
        if (!isWindowsStyle) return;
        
        BOOL isDark = NO;
        if (@available(macOS 10.14, *)) {
            isDark = [NSApp.effectiveAppearance bestMatchFromAppearancesWithNames:@[NSAppearanceNameDarkAqua, NSAppearanceNameAqua]] == NSAppearanceNameDarkAqua;
        }
        
        [CATransaction begin];
        [CATransaction setAnimationDuration:0.1];
        
        if ([button isEqual:[window standardWindowButton:NSWindowCloseButton]]) {
            button.layer.backgroundColor = [NSColor redColor].CGColor;
            // Update close symbol to white
            for (CALayer *layer in button.layer.sublayers) {
                if ([layer.name isEqualToString:@"WindowsStyleContainer"]) {
                    for (CALayer *symbolLayer in layer.sublayers) {
                        if ([symbolLayer isKindOfClass:[CAShapeLayer class]]) {
                            ((CAShapeLayer *)symbolLayer).strokeColor = [NSColor whiteColor].CGColor;
                        }
                    }
                }
            }
        } else {
            CGFloat alpha = 0.3;
            button.layer.backgroundColor = isDark ? 
                [[NSColor colorWithWhite:1.0 alpha:alpha] CGColor] : 
                [[NSColor colorWithWhite:0.0 alpha:alpha] CGColor];
        }
        
        [CATransaction commit];
        
    } @catch (NSException *e) {
        NSLog(@"[macwmfx] Error in handleMouseEntered: %@ - %@", e.name, e.reason);
    }
}

- (void)handleMouseExited:(NSEvent *)event forWindow:(NSWindow *)window {
    @try {
        if (!gTrafficLightsConfig.enabled || !event || !window) return;
        
        NSButton *button = (NSButton *)event.trackingArea.owner;
        if (![button isKindOfClass:[NSButton class]]) return;
        
        BOOL isWindowsStyle = [gTrafficLightsConfig.style isEqualToString:@"windows"];
        if (!isWindowsStyle) return;
        
        [CATransaction begin];
        [CATransaction setAnimationDuration:0.1];
        
        button.layer.backgroundColor = [NSColor clearColor].CGColor;
        
        // Reset symbol color
        BOOL isDark = NO;
        if (@available(macOS 10.14, *)) {
            isDark = [NSApp.effectiveAppearance bestMatchFromAppearancesWithNames:@[NSAppearanceNameDarkAqua, NSAppearanceNameAqua]] == NSAppearanceNameDarkAqua;
        }
        
        BOOL isActive = window.isKeyWindow;
        NSColor *symbolColor = isActive ? 
            (isDark ? [NSColor whiteColor] : [NSColor blackColor]) :
            [NSColor grayColor];
        
        for (CALayer *layer in button.layer.sublayers) {
            if ([layer.name isEqualToString:@"WindowsStyleContainer"]) {
                for (CALayer *symbolLayer in layer.sublayers) {
                    if ([symbolLayer isKindOfClass:[CAShapeLayer class]]) {
                        ((CAShapeLayer *)symbolLayer).strokeColor = symbolColor.CGColor;
                    }
                }
            }
        }
        
        [CATransaction commit];
        
    } @catch (NSException *e) {
        NSLog(@"[macwmfx] Error in handleMouseExited: %@ - %@", e.name, e.reason);
    }
}

- (void)handleButtonClick:(NSButton *)button {
    @try {
        if (!button || !button.window) return;
        
        NSWindow *window = button.window;
        
        if ([button isEqual:[window standardWindowButton:NSWindowCloseButton]]) {
            [window close];
        } else if ([button isEqual:[window standardWindowButton:NSWindowMiniaturizeButton]]) {
            [window miniaturize:nil];
        } else if ([button isEqual:[window standardWindowButton:NSWindowZoomButton]]) {
            [window zoom:nil];
        }
    } @catch (NSException *e) {
        NSLog(@"[macwmfx] Error in handleButtonClick: %@ - %@", e.name, e.reason);
    }
}

- (void)loadConfig {
    NSString *configPath = [[NSBundle mainBundle] pathForResource:@"config_example" ofType:@"json"];
    NSData *data = [NSData dataWithContentsOfFile:configPath];
    if (!data) {
        NSLog(@"[macwmfx] Error: Could not load config file");
        return;
    }
    NSError *error = nil;
    NSDictionary *config = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
    if (error) {
        NSLog(@"[macwmfx] Error parsing config: %@", error.localizedDescription);
        return;
    }
    NSDictionary *trafficLightsConfig = config[@"window"][@"trafficLights"];
    if (trafficLightsConfig) {
        gTrafficLightsConfig.enabled = [trafficLightsConfig[@"enabled"] boolValue];
        gTrafficLightsConfig.style = trafficLightsConfig[@"style"];
        gTrafficLightsConfig.shape = trafficLightsConfig[@"shape"];
        gTrafficLightsConfig.order = trafficLightsConfig[@"order"];
        gTrafficLightsConfig.size = [trafficLightsConfig[@"size"] floatValue];
        gTrafficLightsConfig.padding = [trafficLightsConfig[@"padding"] floatValue];
        gTrafficLightsConfig.position = trafficLightsConfig[@"position"];
        NSDictionary *customColor = trafficLightsConfig[@"customColor"];
        if (customColor) {
            gTrafficLightsConfig.customColor.enabled = [customColor[@"enabled"] boolValue];
            gTrafficLightsConfig.customColor.active.stop = customColor[@"active"][@"stop"];
            gTrafficLightsConfig.customColor.active.yield = customColor[@"active"][@"yield"];
            gTrafficLightsConfig.customColor.active.go = customColor[@"active"][@"go"];
            gTrafficLightsConfig.customColor.inactive.stop = customColor[@"inactive"][@"stop"];
            gTrafficLightsConfig.customColor.inactive.yield = customColor[@"inactive"][@"yield"];
            gTrafficLightsConfig.customColor.inactive.go = customColor[@"inactive"][@"go"];
            gTrafficLightsConfig.customColor.hover.stop = customColor[@"hover"][@"stop"];
            gTrafficLightsConfig.customColor.hover.yield = customColor[@"hover"][@"yield"];
            gTrafficLightsConfig.customColor.hover.go = customColor[@"hover"][@"go"];
        }
    }
}

@end

// Swizzle interface for window management
ZKSwizzleInterface(BS_NSWindow_TrafficLightsController, NSWindow, NSWindow)

@implementation BS_NSWindow_TrafficLightsController

- (void)makeKeyAndOrderFront:(id)sender {
    @try {
        ZKOrig(void, sender);
        [[TrafficLightsController sharedInstance] updateTrafficLights:self];
    } @catch (NSException *e) {
        NSLog(@"[macwmfx] Error in makeKeyAndOrderFront: %@ - %@", e.name, e.reason);
    }
}

- (void)becomeKeyWindow {
    @try {
        ZKOrig(void);
        [[TrafficLightsController sharedInstance] updateTrafficLights:self];
    } @catch (NSException *e) {
        NSLog(@"[macwmfx] Error in becomeKeyWindow: %@ - %@", e.name, e.reason);
    }
}

- (void)resignKeyWindow {
    @try {
        ZKOrig(void);
        [[TrafficLightsController sharedInstance] updateTrafficLights:self];
    } @catch (NSException *e) {
        NSLog(@"[macwmfx] Error in resignKeyWindow: %@ - %@", e.name, e.reason);
    }
}

- (void)orderFront:(id)sender {
    @try {
        ZKOrig(void, sender);
        [[TrafficLightsController sharedInstance] updateTrafficLights:self];
    } @catch (NSException *e) {
        NSLog(@"[macwmfx] Error in orderFront: %@ - %@", e.name, e.reason);
    }
}

- (void)orderOut:(id)sender {
    @try {
        ZKOrig(void, sender);
        [[TrafficLightsController sharedInstance] updateTrafficLights:self];
    } @catch (NSException *e) {
        NSLog(@"[macwmfx] Error in orderOut: %@ - %@", e.name, e.reason);
    }
}

- (void)setStyleMask:(NSWindowStyleMask)styleMask {
    @try {
        ZKOrig(void, styleMask);
        [[TrafficLightsController sharedInstance] updateTrafficLights:self];
    } @catch (NSException *e) {
        NSLog(@"[macwmfx] Error in setStyleMask: %@ - %@", e.name, e.reason);
    }
}

- (void)mouseEntered:(NSEvent *)event {
    [[TrafficLightsController sharedInstance] handleMouseEntered:event forWindow:self];
}

- (void)mouseExited:(NSEvent *)event {
    [[TrafficLightsController sharedInstance] handleMouseExited:event forWindow:self];
}

@end 