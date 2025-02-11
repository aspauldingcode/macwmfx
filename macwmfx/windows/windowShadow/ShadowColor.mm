// //
// //  ShadowColor.mm
// //  macwmfx
// //
// //  Created by Alex "aspauldingcode" on 11/13/24.
// //  Copyright (c) 2025 Alex "aspauldingcode". All rights reserved.
// //

// #import <Foundation/Foundation.h>
// #import <AppKit/AppKit.h>
// #import <CoreGraphics/CoreGraphics.h>
// #import <CoreImage/CoreImage.h>
// #include "../../headers/macwmfx_globals.h"
// #include <objc/runtime.h>
// #include <dlfcn.h>
// #include <setjmp.h>
// #include <signal.h>

// // Global shadow config
// extern ShadowConfig gShadowConfig;
// CFDictionaryRef (*OriginalShadowDataFunc)(int windowID);

// // Global jump buffer for signal handling
// static sigjmp_buf jumpBuffer;

// // Signal handler for dangerous operations
// static void shadowSignalHandler(int sig) {
//     // Jump out if a signal (e.g. SIGSEGV) occurs.
//     siglongjmp(jumpBuffer, 1);
// }

// // Helper function to create a custom shadow
// CGImageRef CreateCustomShadow(NSColor *color, CGSize size, CGFloat blur) {
//     // Create a bitmap context
//     CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
//     CGContextRef context = CGBitmapContextCreate(NULL, 
//                                                size.width, 
//                                                size.height, 
//                                                8, // bits per component
//                                                size.width * 4, // bytes per row
//                                                colorSpace,
//                                                kCGImageAlphaPremultipliedLast);
    
//     // Set shadow color and parameters
//     CGContextSetShadowWithColor(context, CGSizeZero, blur, [color CGColor]);
    
//     // Draw shadow
//     CGRect rect = CGRectMake(blur, blur, size.width - 2 * blur, size.height - 2 * blur);
//     CGContextFillRect(context, rect);
    
//     // Create image from context
//     CGImageRef image = CGBitmapContextCreateImage(context);
    
//     // Cleanup
//     CGContextRelease(context);
//     CGColorSpaceRelease(colorSpace);
    
//     return image;
// }

// // Main shadow customization function (with added safety)
// CFDictionaryRef CustomShadowData(int windowID) {
//     // If our custom shadow is not enabled, immediately fall back.
//     if (!gShadowConfig.enabled || !gShadowConfig.customColor.enabled) {
//         return OriginalShadowDataFunc(windowID);
//     }
    
//     // Set up our signal handler to catch segmentation faults.
//     struct sigaction oldAction, newAction;
//     newAction.sa_handler = shadowSignalHandler;
//     sigemptyset(&newAction.sa_mask);
//     newAction.sa_flags = 0;
//     sigaction(SIGSEGV, &newAction, &oldAction);
//     // (You can add extra signals such as SIGBUS if needed.)
    
//     // Use sigsetjmp to mark a safe spot.
//     if (sigsetjmp(jumpBuffer, 1) != 0) {
//         // A signal was caught. Restore the original handler then safely fall back.
//         NSLog(@"[macwmfx] Signal caught during custom shadow creation, falling back");
//         sigaction(SIGSEGV, &oldAction, NULL);
//         return OriginalShadowDataFunc(windowID);
//     }
    
//     CFDictionaryRef shadowData = NULL;
//     @try {
//         // Convert hex string to color using ConfigParser
//         NSColor *shadowColor = [[ConfigParser sharedInstance] colorFromHexString:gShadowConfig.customColor.active];
//         if (!shadowColor) {
//             NSLog(@"[macwmfx] Failed to parse shadow color, using original");
//             shadowData = OriginalShadowDataFunc(windowID);
//         } else {
//             // Create shadow image
//             CGSize shadowSize = CGSizeMake(600, 600);
//             CGFloat blurRadius = 50.0;
//             CGImageRef shadowImage = CreateCustomShadow(shadowColor, shadowSize, blurRadius);
            
//             // Create shadow properties dictionary
//             CFMutableDictionaryRef customShadowData = CFDictionaryCreateMutable(
//                 kCFAllocatorDefault, 0,
//                 &kCFTypeDictionaryKeyCallBacks,
//                 &kCFTypeDictionaryValueCallBacks);
            
//             // Set shadow properties
//             CFDictionarySetValue(customShadowData, CFSTR("Image"), shadowImage);
            
//             // Use a default opacity since we're using NSColor directly
//             CGFloat opacity = 0.5;
//             CFNumberRef opacityRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberFloatType, &opacity);
//             CFDictionarySetValue(customShadowData, CFSTR("Opacity"), opacityRef);
            
//             CGFloat offset = 30.0;
//             CFNumberRef offsetRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberFloatType, &offset);
//             CFDictionarySetValue(customShadowData, CFSTR("Offset"), offsetRef);
            
//             // Cleanup
//             CGImageRelease(shadowImage);
//             CFRelease(opacityRef);
//             CFRelease(offsetRef);
            
//             shadowData = customShadowData;
//         }
//     }
//     @catch (NSException *exception) {
//         NSLog(@"[macwmfx] Exception occurred in custom shadow: %@, falling back", exception);
//         shadowData = OriginalShadowDataFunc(windowID);
//     }
    
//     // Always restore the old signal handler.
//     sigaction(SIGSEGV, &oldAction, NULL);
    
//     return shadowData;
// }

// // Initialize shadow customization
// void setupShadow() {
//     NSLog(@"[macwmfx] Setting up shadow customization...");
//     gShadowConfig.enabled = YES;
//     gShadowConfig.customColor.enabled = YES;
    
//     void *gum = dlopen("/usr/local/bin/ammonia/fridagum.dylib", RTLD_NOW | RTLD_GLOBAL);
//     if (!gum) {
//         NSLog(@"[macwmfx] Failed to load fridagum.dylib: %s", dlerror());
//         return;
//     }
    
//     typedef void* (*FindExportFunc)(const char*, const char*);
//     FindExportFunc find_export = (FindExportFunc)dlsym(gum, "gum_module_find_export_by_name");
//     if (!find_export) {
//         NSLog(@"[macwmfx] Failed to find gum_module_find_export_by_name");
//         return;
//     }
    
//     void *shadowFunc = find_export("SkyLight", "SLWindowServerShadowData");
//     if (shadowFunc) {
//         NSLog(@"[macwmfx] Found SLWindowServerShadowData");
//         OriginalShadowDataFunc = (CFDictionaryRef (*)(int))shadowFunc;
//         NSLog(@"[macwmfx] Shadow customization setup complete");
//     } else {
//         NSLog(@"[macwmfx] Failed to find SLWindowServerShadowData");
//     }
// }
