//
//  TrafficLightsColors.m
//  macwmfx
//
//  Created by Alex "aspauldingcode" on 01/09/25.
//  Copyright (c) 2025 Alex "aspauldingcode". All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "../../headers/macwmfx_globals.h"

ZKSwizzleInterface(BS_NSWindow_TrafficLightsColors, NSWindow, NSWindow)

@implementation BS_NSWindow_TrafficLightsColors

- (void)makeKeyAndOrderFront:(id)sender {
    ZKOrig(void, sender);
    
    // Skip if this is not a regular window
    if (!(self.styleMask & NSWindowStyleMaskTitled)) return;
    
    [self updateTrafficLightColors];
    
    // Subscribe to config changes
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self
                                                      selector:@selector(handleConfigChange:)
                                                          name:@"com.macwmfx.configChanged"
                                                        object:nil];
}

- (void)dealloc {
    [[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
    ZKOrig(void);
}

- (void)handleConfigChange:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateTrafficLightColors];
    });
}

- (void)updateTrafficLightColors {
    @try {
        // Skip if this is not a regular window
        if (!(self.styleMask & NSWindowStyleMaskTitled)) return;
        
        // Get the traffic light buttons
        NSButton *closeButton = [self standardWindowButton:NSWindowCloseButton];
        NSButton *minimizeButton = [self standardWindowButton:NSWindowMiniaturizeButton];
        NSButton *zoomButton = [self standardWindowButton:NSWindowZoomButton];
        
        if (!closeButton || !minimizeButton || !zoomButton) {
            NSLog(@"[macwmfx] Traffic light buttons not found for colors");
            return;
        }
        
        // Reset colors to default first
        for (NSButton *button in @[closeButton, minimizeButton, zoomButton]) {
            button.wantsLayer = YES;
            button.layer.backgroundColor = nil;
        }
        
        // Only proceed if traffic lights are enabled and custom colors are enabled
        if (!gTrafficLightsConfig.enabled || !gTrafficLightsConfig.customColor.enabled) return;
        
        ConfigParser *parser = [ConfigParser sharedInstance];
        BOOL isActive = self.isKeyWindow;
        
        // Setup tracking areas for hover effects if not already set
        [self setupTrackingAreasForButton:closeButton];
        [self setupTrackingAreasForButton:minimizeButton];
        [self setupTrackingAreasForButton:zoomButton];
        
        // Apply colors based on window state
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
        
        NSLog(@"[macwmfx] Applied %@ traffic light colors", isActive ? @"active" : @"inactive");
        
    } @catch (NSException *e) {
        NSLog(@"[macwmfx] Error updating traffic light colors: %@", e);
    }
}

- (void)setupTrackingAreasForButton:(NSButton *)button {
    // Remove existing tracking areas
    for (NSTrackingArea *area in button.trackingAreas) {
        [button removeTrackingArea:area];
    }
    
    // Add new tracking area
    NSTrackingArea *trackingArea = [[NSTrackingArea alloc] initWithRect:button.bounds
                                                              options:(NSTrackingMouseEnteredAndExited | 
                                                                     NSTrackingActiveAlways |
                                                                     NSTrackingInVisibleRect)
                                                                owner:self
                                                             userInfo:@{@"button": button}];
    [button addTrackingArea:trackingArea];
}

- (void)mouseEntered:(NSEvent *)event {
    if (!gTrafficLightsConfig.enabled || !gTrafficLightsConfig.customColor.enabled) return;
    
    NSButton *button = event.trackingArea.userInfo[@"button"];
    if (!button) return;
    
    ConfigParser *parser = [ConfigParser sharedInstance];
    
    // Apply hover colors
    if ([button isEqual:[self standardWindowButton:NSWindowCloseButton]] && 
        gTrafficLightsConfig.customColor.hover.stop) {
        button.layer.backgroundColor = [parser colorFromHexString:gTrafficLightsConfig.customColor.hover.stop].CGColor;
    }
    else if ([button isEqual:[self standardWindowButton:NSWindowMiniaturizeButton]] && 
             gTrafficLightsConfig.customColor.hover.yield) {
        button.layer.backgroundColor = [parser colorFromHexString:gTrafficLightsConfig.customColor.hover.yield].CGColor;
    }
    else if ([button isEqual:[self standardWindowButton:NSWindowZoomButton]] && 
             gTrafficLightsConfig.customColor.hover.go) {
        button.layer.backgroundColor = [parser colorFromHexString:gTrafficLightsConfig.customColor.hover.go].CGColor;
    }
}

- (void)mouseExited:(NSEvent *)event {
    if (!gTrafficLightsConfig.enabled || !gTrafficLightsConfig.customColor.enabled) return;
    
    NSButton *button = event.trackingArea.userInfo[@"button"];
    if (!button) return;
    
    // Restore active/inactive colors
    [self updateTrafficLightColors];
}

- (void)becomeKeyWindow {
    ZKOrig(void);
    [self updateTrafficLightColors];
}

- (void)resignKeyWindow {
    ZKOrig(void);
    [self updateTrafficLightColors];
}

@end
