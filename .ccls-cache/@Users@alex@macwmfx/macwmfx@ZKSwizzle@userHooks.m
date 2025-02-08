//
//  userhooks.m
//  menuheights
//
//  Created by knives on 2/5/24.
//


#include <Foundation/Foundation.h>
#include <ImageIO/ImageIO.h>
#include <objc/message.h>
#include <pwd.h>
#include <dlfcn.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>
#include <sys/_types/_null.h>
#include <sys/types.h>
#include <unistd.h>
#include <string.h>
#include <IOSurface/IOSurface.h>
#include <CoreFoundation/CoreFoundation.h>
#include <CoreGraphics/CoreGraphics.h>
#include <objc/objc.h>
#include <objc/runtime.h>

#include <AppKit/AppKit.h>
#include <QuartzCore/QuartzCore.h>

#include "../headers/symrez.h"

#include <mach/mach_vm.h>
#include <sys/mman.h>

CGImageRef ImageFromFile(const char *filePath) 
{
    CGDataProviderRef dataProvider = CGDataProviderCreateWithFilename(filePath);
    return CGImageCreateWithPNGDataProvider(dataProvider, NULL, NO, kCGRenderingIntentDefault);
}

// Add these declarations near the top of the file with other globals
bool WindowHideShadow = false;  // Controls whether window shadows are hidden
bool WindowDecorations = true;  // Controls whether window decorations are shown
bool MenubarGraphic = false;    // Controls whether custom menubar graphic is used
int __height = 24;              // Default menubar height

// Fix function pointer declarations to match types
CGError (*ServerSetHasActiveShadowOld)(long, uint);
long (*ServerShadowSurfaceOld)(void*, void*, void*);

// Add this function declaration near the top with other function declarations
void DrawNineSlice(CGContextRef context, CGImageRef image, CGRect bounds, int inset);

// Add function prototype
void (*MenubarLayersOld)(void*, bool);

void MenubarLayersNew(void *param_1, bool param_2)
{
    MenubarLayersOld(param_1, param_2);

    if (MenubarGraphic)
    {
        // Fetching the class of the layer object with proper casting
        CALayer *layer_one = (__bridge CALayer *)*(void **)((char *)param_1 + 0x10);
        CALayer *layer_two = (__bridge CALayer *)*(void **)((char *)param_1 + 0x18);

        layer_one.contents = (__bridge id)ImageFromFile("/Library/wsfun/menubar.png");
        layer_two.contents = (__bridge id)ImageFromFile("/Library/wsfun/menubar.png");
    }
}

// Add the DrawNineSlice implementation if you don't have it elsewhere
void DrawNineSlice(CGContextRef context, CGImageRef image, CGRect bounds, int __unused inset) 
{
    CGContextDrawImage(context, bounds, image);
}

CGRect (*HeightOld)();
CGRect HeightNew()
{
    CGRect orig = HeightOld();
    orig.size.height = __height;
    return orig;
}

void ClientRenderHeightNew(int __unused did, int * height)
{
    *height = __height;
    return;
}

#pragma mark - shadows

struct ServerShadow {
    IOSurfaceRef surface;
    // Other members...
};

CGImageRef shadow_png = NULL;

void SwapRedBlue(IOSurfaceRef surface)
{
    if (!surface) return;

    uint32_t width = (uint32_t)IOSurfaceGetWidth(surface);
    uint32_t height = (uint32_t)IOSurfaceGetHeight(surface);
    size_t bytesPerElement = IOSurfaceGetBytesPerElement(surface);
    size_t bytesPerRow = IOSurfaceGetBytesPerRow(surface);
    void *baseAddress = IOSurfaceGetBaseAddress(surface);

    for (uint32_t y = 0; y < height; y++) {
        for (uint32_t x = 0; x < width; x++) {
            size_t offset = y * bytesPerRow + x * bytesPerElement;
            uint8_t *pixel = ((uint8_t *)baseAddress) + offset;
            uint8_t temp = pixel[0];
            pixel[0] = pixel[2];
            pixel[2] = temp;
        }
    }
}

long ServerShadowSurfaceNew(void *shadow_ptr, void *param_1, void *param_2)
{
    if (!shadow_png)
        shadow_png = ImageFromFile("/Library/wsfun/shadow.png");

    long k = ServerShadowSurfaceOld(shadow_ptr, param_1, param_2);
    struct ServerShadow *shadow = (struct ServerShadow *)shadow_ptr;

    IOSurfaceLock(shadow->surface, 0, NULL);
    int width = IOSurfaceGetWidth(shadow->surface);
    int height = IOSurfaceGetHeight(shadow->surface);

    CGContextRef context = CGBitmapContextCreate(IOSurfaceGetBaseAddress(shadow->surface),
                                               width, height, 8,
                                               IOSurfaceGetBytesPerRow(shadow->surface),
                                               CGColorSpaceCreateDeviceRGB(),
                                               kCGImageAlphaPremultipliedLast);

    if (WindowHideShadow) {
        CGContextClearRect(context, CGRectMake(0, 0, width, height));
    }

    if (WindowDecorations) {
        DrawNineSlice(context, shadow_png, CGRectMake(0, 0, width, height), 19);
    }
    
    CGContextFlush(context);
    CGContextRelease(context);

    SwapRedBlue(shadow->surface);
    IOSurfaceUnlock(shadow->surface, 0, 0);

    return k;
}

CGError (*ServerSetHasActiveShadowOld)();
CGError ServerSetHasActiveShadowNew(long param_1, uint param_2)
{
    return ServerSetHasActiveShadowOld(param_1, 0);
}

bool WantsRenderAbove() {
    return false;
}

bool NinePartable() {
    return true;
}

// Function pointer declarations
typedef struct GumInterceptor GumInterceptor;
typedef void* (*GumModuleFindExportByName)(const char* module_name, const char* symbol_name);
typedef void (*GumInterceptorReplace)(void* function, void* replacement_function, void** original_function);

#ifdef __cplusplus
extern "C" {
#endif

void ClientHook(void * func, void * newFunc, void ** old)
{
    if (func != NULL) 
    { 
        NSLog(@"[macwmfx] Saving original function pointer");
        // Just save the original function pointer
        *old = func;
        NSLog(@"[macwmfx] Original function saved at %p", *old);
    }
}

#ifdef __cplusplus
}
#endif

void InstantiateClientHooks(GumInterceptor *interceptor) {
    void *gum = dlopen("/usr/local/bin/ammonia/fridagum.dylib", RTLD_NOW | RTLD_GLOBAL);
    if (!gum) {
        NSLog(@"[macwmfx] Failed to load fridagum.dylib");
        return;
    }

    typedef void* (*FindExportFunc)(const char*, const char*);
    typedef void (*ReplaceFunc)(void*, void*, void**);
    
    FindExportFunc find_export = (FindExportFunc)dlsym(gum, "gum_module_find_export_by_name");
    ReplaceFunc replace_function = (ReplaceFunc)dlsym(gum, "gum_interceptor_replace_function");
    
    if (!find_export || !replace_function) {
        NSLog(@"[macwmfx] Failed to find required gum functions");
        return;
    }

    // Install shadow hooks
    void *wantsRenderAboveFunc = find_export("SkyLight", "_WSWindowShadowWantsRenderAbove");
    void *ninePartableFunc = find_export("SkyLight", "__ZL28is_shadow_mask_nine_partableP9CGXWindow");
    void *hasActiveShadowFunc = find_export("SkyLight", "_WSWindowSetHasActiveShadow");
    void *shadowSurfaceFunc = find_export("SkyLight", "__ZN8WSShadowC1EP11__IOSurface19WSShadowDescription");
    
    if (wantsRenderAboveFunc && ninePartableFunc && hasActiveShadowFunc && shadowSurfaceFunc) {
        replace_function(wantsRenderAboveFunc, (void*)WantsRenderAbove, NULL);
        replace_function(ninePartableFunc, (void*)NinePartable, NULL);
        replace_function(hasActiveShadowFunc, (void*)ServerSetHasActiveShadowNew, (void**)&ServerSetHasActiveShadowOld);
        replace_function(shadowSurfaceFunc, (void*)ServerShadowSurfaceNew, (void**)&ServerShadowSurfaceOld);
        NSLog(@"[macwmfx] Shadow hooks installed successfully");
    }
}

void __attribute__((visibility("default"))) LoadFunction(GumInterceptor *interceptor) {
    InstantiateClientHooks(interceptor);
}