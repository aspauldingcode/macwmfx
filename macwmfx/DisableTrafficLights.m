//
//  DisableTrafficLights.m
//  DisableTrafficLights
//
//  Created by Alex Spaulding "aspauldingcode" on 12/24/2024
//  Copyright (c) 2024 Alex Spaulding. All rights reserved.
//

#pragma mark - Library/Header Imports

#import <AppKit/AppKit.h>

#import <objc/runtime.h>

#import "ZKSwizzle.h"

#include <os/log.h>
#define DLog(N, ...) os_log_with_type(os_log_create("com.aspauldingcode.macwmfx", "DEBUG"),OS_LOG_TYPE_DEFAULT,N ,##__VA_ARGS__)


#pragma mark - Global Variables

NSBundle *bundle;
NSStatusItem *statusItem;

static NSString *const preferencesSuiteName = @"com.aspauldingcode.macwmfx";


#pragma mark - Main Interface

@interface DisableTrafficLights : NSObject
+ (instancetype)sharedInstance;
@end

DisableTrafficLights* plugin;


#pragma mark - Main Implementation

@implementation DisableTrafficLights

+ (DisableTrafficLights*)sharedInstance {
    static DisableTrafficLights* plugin = nil;
    
    if (!plugin)
        plugin = [[DisableTrafficLights alloc] init];
    
    return plugin;
}

// Called on MacForge plugin initialization
+ (void)load {
    // Create plugin singleton + bundle & statusItem
    plugin = [DisableTrafficLights sharedInstance];
        
//    // Log loading
//    NSUInteger major = [[NSProcessInfo processInfo] operatingSystemVersion].majorVersion;
//    NSUInteger minor = [[NSProcessInfo processInfo] operatingSystemVersion].minorVersion;
//    DLog("%{public}@: Loaded (%{public}@ - macOS %ld.%ld)", [self className], [[NSBundle mainBundle] bundleIdentifier], (long)major, (long)minor);
}

@end


#pragma mark - *** Handling

ZKSwizzleInterface(BS_NSWindow, NSWindow, NSResponder)

@implementation BS_NSWindow

// "Returns the window button of a given window button kind in the window's view hierarchy."
- (nullable NSButton *)standardWindowButton:(NSWindowButton)b {
    // Call original method
    return ZKOrig(NSButton*, b);
}

// "Moves the window to the front of the screen list, within its level, and makes it the key window; that is, it shows the window."
- (void)makeKeyAndOrderFront:(id)sender {
    // Call original method
    ZKOrig(void, sender);
    
    // Hide traffic lights
    [self hideTrafficLights];
}

// Hide traffic lights
- (void)hideTrafficLights {
    NSButton* close = [self standardWindowButton:NSWindowCloseButton];
    NSButton* miniaturize = [self standardWindowButton:NSWindowMiniaturizeButton];
    NSButton* zoom = [self standardWindowButton:NSWindowZoomButton];

    [self hideButton:close];
    [self hideButton:miniaturize];
    [self hideButton:zoom];
}

// Hide traffic light
- (void)hideButton:(NSButton*)button {
    if (button) {
        button.hidden = YES;
    }
}

// Remove traffic light
- (void)removeButton:(NSButton*)button {
    if (button) {
        [button removeFromSuperview];
    }
}

@end