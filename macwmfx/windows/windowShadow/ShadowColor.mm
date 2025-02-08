//
//  ShadowColor.mm
//  macwmfx
//
//  Created by Alex "aspauldingcode" on 11/13/24.
//  Copyright (c) 2024 Alex "aspauldingcode". All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <CoreGraphics/CoreGraphics.h>
#include "../../headers/macwmfx_globals.h"
#include <objc/runtime.h>
#include <dlfcn.h>

// Global shadow config (defined in macwmfx_globals.h)
extern ShadowConfig gShadowConfig;

// Function pointer for original shadow data function
CFDictionaryRef (*OriginalShadowDataFunc)(int windowID);

CFDictionaryRef CustomShadowData(int windowID) {
    // Get original shadow data
    CFDictionaryRef originalData = OriginalShadowDataFunc(windowID);
    if (!originalData) return NULL;
    
    // Create mutable copy to modify shadow properties
    CFMutableDictionaryRef modifiedData = CFDictionaryCreateMutableCopy(
        kCFAllocatorDefault, 
        0,
        originalData
    );
    
    // Use the global shadow config color
    NSColor *nsColor = gShadowConfig.color;
    CGFloat red, green, blue, alpha;
    [nsColor getRed:&red green:&green blue:&blue alpha:&alpha];
    CGColorRef shadowColor = CGColorCreateGenericRGB(red, green, blue, alpha);
    
    CFDictionarySetValue(modifiedData, CFSTR("Color"), shadowColor);
    CGColorRelease(shadowColor);
    
    CFRelease(originalData);
    return modifiedData;
}

void initializeShadowConfig() {
    // Set default shadow configuration
    gShadowConfig.enabled = YES;
    gShadowConfig.color = [NSColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.5];
}

void updateAllWindows() {
    CFArrayRef windows = CGWindowListCopyWindowInfo(
        kCGWindowListOptionOnScreenOnly,
        kCGNullWindowID
    );
    
    CFIndex count = CFArrayGetCount(windows);
    for (CFIndex i = 0; i < count; i++) {
        CFDictionaryRef windowInfo = (CFDictionaryRef)CFArrayGetValueAtIndex(windows, i);
        
        CFNumberRef windowIDRef = (CFNumberRef)CFDictionaryGetValue(windowInfo, kCGWindowNumber);
        if (windowIDRef) {
            int windowID;
            CFNumberGetValue(windowIDRef, kCFNumberIntType, &windowID);
            
            if (OriginalShadowDataFunc) {
                OriginalShadowDataFunc(windowID);
            }
        }
    }
    CFRelease(windows);
}

// Entry point for initializing shadow settings
void setupShadow() {
    initializeShadowConfig();
    updateAllWindows();
}

// Hook the shadow data function using the existing ClientHook infrastructure
extern "C" void ClientHook(void * func, void * newParam, void ** old);

void hookShadowData() {
    void *skylight = dlopen("/System/Library/PrivateFrameworks/SkyLight.framework/SkyLight", RTLD_NOW);
    if (skylight) {
        void *shadowDataSymbol = dlsym(skylight, "SLWindowServerShadowData");
        if (shadowDataSymbol) {
            ClientHook(shadowDataSymbol, (void*)CustomShadowData, (void**)&OriginalShadowDataFunc);
        }
        dlclose(skylight);
    }
}
