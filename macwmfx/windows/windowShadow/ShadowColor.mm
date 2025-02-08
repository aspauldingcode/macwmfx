// //
// //  ShadowColor.mm
// //  macwmfx
// //
// //  Created by Alex "aspauldingcode" on 11/13/24.
// //  Copyright (c) 2024 Alex "aspauldingcode". All rights reserved.
// //

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <CoreGraphics/CoreGraphics.h>
#import <CoreImage/CoreImage.h>
#include "../../headers/macwmfx_globals.h"
#include <objc/runtime.h>
#include <dlfcn.h>

// Global shadow config
extern ShadowConfig gShadowConfig;
CFDictionaryRef (*OriginalShadowDataFunc)(int windowID);

@interface NSColor (HexString)
+ (NSColor *)colorWithHexString:(NSString *)hexString;
@end

@implementation NSColor (HexString)
+ (NSColor *)colorWithHexString:(NSString *)hexString {
    NSString *cleanString = [hexString stringByReplacingOccurrencesOfString:@"#" withString:@""];
    if([cleanString length] == 3) {
        cleanString = [NSString stringWithFormat:@"%@%@%@%@%@%@",
                      [cleanString substringWithRange:NSMakeRange(0, 1)],[cleanString substringWithRange:NSMakeRange(0, 1)],
                      [cleanString substringWithRange:NSMakeRange(1, 1)],[cleanString substringWithRange:NSMakeRange(1, 1)],
                      [cleanString substringWithRange:NSMakeRange(2, 1)],[cleanString substringWithRange:NSMakeRange(2, 1)]];
    }
    unsigned int baseValue;
    [[NSScanner scannerWithString:cleanString] scanHexInt:&baseValue];
    
    CGFloat red = ((baseValue >> 16) & 0xFF)/255.0f;
    CGFloat green = ((baseValue >> 8) & 0xFF)/255.0f;
    CGFloat blue = ((baseValue) & 0xFF)/255.0f;
    
    return [NSColor colorWithRed:red green:green blue:blue alpha:1.0];
}
@end

// Helper function to create a shadow directly
CGImageRef CreateCustomShadow(NSColor *color, CGSize size, CGFloat blur) {
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(NULL,
                                               size.width,
                                               size.height,
                                               8,
                                               size.width * 4,
                                               colorSpace,
                                               kCGImageAlphaPremultipliedLast);
    
    // Create path for shadow shape
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, CGRectInset(CGRectMake(0, 0, size.width, size.height), blur * 2, blur * 2));
    
    // Set shadow parameters
    CGContextSetShadowWithColor(context, CGSizeMake(0, 0), blur, [color CGColor]);
    
    // Fill the path with shadow
    CGContextAddPath(context, path);
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillPath(context);
    
    // Create final image
    CGImageRef shadowImage = CGBitmapContextCreateImage(context);
    
    // Cleanup
    CGPathRelease(path);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    return shadowImage;
}

CFDictionaryRef CustomShadowData(int windowID) {
    NSLog(@"[macwmfx] CustomShadowData called for window %d", windowID);
    
    if (!gShadowConfig.enabled || !gShadowConfig.customColor.enabled) {
        NSLog(@"[macwmfx] Shadow customization disabled, using original");
        return OriginalShadowDataFunc(windowID);
    }
    
    // Get window active state
    CFArrayRef windowList = CGWindowListCopyWindowInfo(kCGWindowListOptionIncludingWindow, windowID);
    bool isActive = false;
    
    if (windowList) {
        if (CFArrayGetCount(windowList) > 0) {
            CFDictionaryRef windowInfo = (CFDictionaryRef)CFArrayGetValueAtIndex(windowList, 0);
            CFNumberRef layerRef = (CFNumberRef)CFDictionaryGetValue(windowInfo, kCGWindowLayer);
            if (layerRef) {
                int layer;
                CFNumberGetValue(layerRef, kCFNumberIntType, &layer);
                isActive = (layer == 0);
            }
        }
        CFRelease(windowList);
    }
    
    // Create custom shadow
    NSString *hexColor = isActive ? gShadowConfig.customColor.active : gShadowConfig.customColor.inactive;
    NSColor *shadowColor = [NSColor colorWithHexString:hexColor];
    
    // Create custom shadow with more pronounced values
    CGSize shadowSize = CGSizeMake(600, 600);  // Larger shadow
    CGFloat blurRadius = isActive ? 50.0 : 30.0;  // More blur
    CGImageRef shadowImage = CreateCustomShadow(shadowColor, shadowSize, blurRadius);
    
    // Create shadow dictionary with more visible values
    CFMutableDictionaryRef shadowData = CFDictionaryCreateMutable(
        kCFAllocatorDefault, 0,
        &kCFTypeDictionaryKeyCallBacks,
        &kCFTypeDictionaryValueCallBacks);
    
    CFDictionarySetValue(shadowData, CFSTR("Image"), shadowImage);
    CGFloat opacity = isActive ? 0.5 : 0.3;  // Higher opacity
    CFNumberRef opacityRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberFloatType, &opacity);
    CFDictionarySetValue(shadowData, CFSTR("Opacity"), opacityRef);
    
    CGFloat offset = 30.0;  // Larger offset
    CFNumberRef offsetRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberFloatType, &offset);
    CFDictionarySetValue(shadowData, CFSTR("Offset"), offsetRef);
    
    // Cleanup
    CGImageRelease(shadowImage);
    CFRelease(opacityRef);
    CFRelease(offsetRef);
    
    return shadowData;
}

void setupShadow() {
    NSLog(@"[macwmfx] Setting up shadow hook...");
    gShadowConfig.enabled = YES;
    gShadowConfig.customColor.enabled = YES;
    
    // Load gum functions from ammonia
    void *gum = dlopen("/usr/local/bin/ammonia/fridagum.dylib", RTLD_NOW | RTLD_GLOBAL);
    if (!gum) {
        NSLog(@"[macwmfx] Failed to load fridagum.dylib: %s", dlerror());
        return;
    }
    
    // Get the function finder from gum with proper casting
    typedef void* (*FindExportFunc)(const char*, const char*);
    FindExportFunc find_export = (FindExportFunc)dlsym(gum, "gum_module_find_export_by_name");
    if (!find_export) {
        NSLog(@"[macwmfx] Failed to find gum_module_find_export_by_name");
        return;
    }
    
    // Find the shadow function
    void *shadowFunc = find_export("SkyLight", "SLWindowServerShadowData");
    if (shadowFunc) {
        NSLog(@"[macwmfx] Found SLWindowServerShadowData");
        OriginalShadowDataFunc = (CFDictionaryRef (*)(int))shadowFunc;
        // The actual hook will be handled by ammonia
    }
}
