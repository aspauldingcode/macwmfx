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
#include "SymRez/SymRez.h"

CGImageRef ImageFromFile(const char *filePath) 
{
    CGDataProviderRef dataProvider = CGDataProviderCreateWithFilename(filePath);
    return CGImageCreateWithPNGDataProvider(dataProvider, NULL, NO, kCGRenderingIntentDefault);
}

#pragma mark - shadows

struct ServerShadow {
    IOSurfaceRef surface;
    // Other members...
};

// to render shadow properly in correct color
void SwapRedBlue(IOSurfaceRef surface)
{
    if (!surface) 
    {
        // Handle null surface
        return;
    }

    // Get surface properties
    uint32_t width = (uint32_t)IOSurfaceGetWidth(surface);
    uint32_t height = (uint32_t)IOSurfaceGetHeight(surface);
    size_t bytesPerElement = IOSurfaceGetBytesPerElement(surface);
    size_t bytesPerRow = IOSurfaceGetBytesPerRow(surface);

    // Get base address of the surface
    void *baseAddress = IOSurfaceGetBaseAddress(surface);

    // Iterate through each pixel
    for (uint32_t y = 0; y < height; y++) 
    {
        for (uint32_t x = 0; x < width; x++) 
        {
            // Calculate the offset for the current pixel
            size_t offset = y * bytesPerRow + x * bytesPerElement;
            
            // Swap red and blue channels
            uint8_t *pixel = ((uint8_t *)baseAddress) + offset;
            uint8_t temp = pixel[0];  // Store red channel temporarily
            pixel[0] = pixel[2];      // Red channel becomes blue
            pixel[2] = temp;          // Blue channel becomes red
        }
    }
}

long (*ServerShadowSurfaceOld)();

#include <CoreGraphics/CoreGraphics.h>

// Draw a nine-slice image
void DrawNineSlice(CGContextRef context, CGImageRef image, CGRect rect, int insets) 
{
    if (!context || !image) return;
    
    CGFloat leftInset = insets;
    CGFloat rightInset = insets;
    CGFloat topInset = insets;
    CGFloat bottomInset = insets;
    
    CGSize imageSize = CGSizeMake(CGImageGetWidth(image), CGImageGetHeight(image));
    
    // Create all sub-images first
    CGImageRef topLeft = CGImageCreateWithImageInRect(image, CGRectMake(0, imageSize.height - topInset, leftInset, topInset));
    CGImageRef topEdge = CGImageCreateWithImageInRect(image, CGRectMake(leftInset, imageSize.height - topInset, imageSize.width - leftInset - rightInset, topInset));
    CGImageRef topRight = CGImageCreateWithImageInRect(image, CGRectMake(imageSize.width - rightInset, imageSize.height - topInset, rightInset, topInset));
    CGImageRef leftEdge = CGImageCreateWithImageInRect(image, CGRectMake(0, topInset, leftInset, imageSize.height - topInset - bottomInset));
    CGImageRef center = CGImageCreateWithImageInRect(image, CGRectMake(leftInset, topInset, imageSize.width - leftInset - rightInset, imageSize.height - topInset - bottomInset));
    CGImageRef rightEdge = CGImageCreateWithImageInRect(image, CGRectMake(imageSize.width - rightInset, topInset, rightInset, imageSize.height - topInset - bottomInset));
    CGImageRef bottomLeft = CGImageCreateWithImageInRect(image, CGRectMake(0, 0, leftInset, bottomInset));
    CGImageRef bottomEdge = CGImageCreateWithImageInRect(image, CGRectMake(leftInset, 0, imageSize.width - leftInset - rightInset, bottomInset));
    CGImageRef bottomRight = CGImageCreateWithImageInRect(image, CGRectMake(imageSize.width - rightInset, 0, rightInset, bottomInset));
    
    // Draw all pieces
    if (topLeft) CGContextDrawImage(context, CGRectMake(rect.origin.x, rect.origin.y, leftInset, topInset), topLeft);
    if (topEdge) CGContextDrawImage(context, CGRectMake(rect.origin.x + leftInset, rect.origin.y, rect.size.width - leftInset - rightInset, topInset), topEdge);
    if (topRight) CGContextDrawImage(context, CGRectMake(rect.origin.x + rect.size.width - rightInset, rect.origin.y, rightInset, topInset), topRight);
    if (leftEdge) CGContextDrawImage(context, CGRectMake(rect.origin.x, rect.origin.y + topInset, leftInset, rect.size.height - topInset - bottomInset), leftEdge);
    if (center) CGContextDrawImage(context, CGRectMake(rect.origin.x + leftInset, rect.origin.y + topInset, rect.size.width - leftInset - rightInset, rect.size.height - topInset - bottomInset), center);
    if (rightEdge) CGContextDrawImage(context, CGRectMake(rect.origin.x + rect.size.width - rightInset, rect.origin.y + topInset, rightInset, rect.size.height - topInset - bottomInset), rightEdge);
    if (bottomLeft) CGContextDrawImage(context, CGRectMake(rect.origin.x, rect.origin.y + rect.size.height - bottomInset, leftInset, bottomInset), bottomLeft);
    if (bottomEdge) CGContextDrawImage(context, CGRectMake(rect.origin.x + leftInset, rect.origin.y + rect.size.height - bottomInset, rect.size.width - leftInset - rightInset, bottomInset), bottomEdge);
    if (bottomRight) CGContextDrawImage(context, CGRectMake(rect.origin.x + rect.size.width - rightInset, rect.origin.y + rect.size.height - bottomInset, rightInset, bottomInset), bottomRight);
    
    // Release all sub-images
    if (topLeft) CGImageRelease(topLeft);
    if (topEdge) CGImageRelease(topEdge);
    if (topRight) CGImageRelease(topRight);
    if (leftEdge) CGImageRelease(leftEdge);
    if (center) CGImageRelease(center);
    if (rightEdge) CGImageRelease(rightEdge);
    if (bottomLeft) CGImageRelease(bottomLeft);
    if (bottomEdge) CGImageRelease(bottomEdge);
    if (bottomRight) CGImageRelease(bottomRight);
}

CGImageRef shadow_png = NULL; 
long ServerShadowSurfaceNew(void * shadow_ptr /* WSShadow:: */, void * param_1,void * param_2)
{
    // Create a new iOSurface first
    long k = ServerShadowSurfaceOld(shadow_ptr, param_1, param_2);
    struct ServerShadow * shadow = (struct ServerShadow *)shadow_ptr;
    
    if (!shadow || !shadow->surface) {
        return k;
    }

    // Load image only once and check for failure
    if (!shadow_png) {
        shadow_png = ImageFromFile("/Library/wsfun/shadow.png");
        if (!shadow_png) {
            return k;
        }
    }

    // Lock surface with error checking
    if (IOSurfaceLock(shadow->surface, 0, NULL) != kIOReturnSuccess) {
        return k;
    }

    int width = IOSurfaceGetWidth(shadow->surface);
    int height = IOSurfaceGetHeight(shadow->surface);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(IOSurfaceGetBaseAddress(shadow->surface),
                                               width,
                                               height,
                                               8,
                                               IOSurfaceGetBytesPerRow(shadow->surface),
                                               colorSpace,
                                               kCGImageAlphaPremultipliedLast);
    CGColorSpaceRelease(colorSpace);
    
    if (!context) {
        IOSurfaceUnlock(shadow->surface, 0, 0);
        return k;
    }

    if (WindowHideShadow) {
        CGContextClearRect(context, CGRectMake(0, 0, width, height));
    } else if (WindowDecorations) {
        CGContextClearRect(context, CGRectMake(0, 0, width, height));
        DrawNineSlice(context, shadow_png, CGRectMake(0, 0, width, height), 1); // Reduced insets
    }
    
    CGContextFlush(context);
    CGContextRelease(context);

    SwapRedBlue(shadow->surface);
    IOSurfaceUnlock(shadow->surface, 0, 0);

    return k;
}


CGError (*ServerSetHasActiveShadowOld)();
CGError ServerSetHasActiveShadowNew(long param_1,uint param_2)
{
    return ServerSetHasActiveShadowOld(param_1, 0); /* 
                                                    setting to zero disables the two states, 
                                                    which also makes drawing easier
                                                    as everything shadow isnt moving.
                                                    */
}

bool WantsRenderAbove() {
    return false;
}

bool NinePartable() {
    return WindowDecorations; // Only return true if decorations are enabled
}

GumInterceptor *magic;
void (*GumInterceptorReplaceFunc)(GumInterceptor * self, gpointer function_address, gpointer replacement_function, gpointer replacement_data, gpointer * original_function);
void *(*GumModuleFindExportByNameFunc)(const gchar * module_name, const gchar * symbol_name);
void (*GumInterceptorBeginTransactionFunc)(GumInterceptor * self);
void (*GumInterceptorEndTransactionFunc)(GumInterceptor * self);

void ClientHook(void * func, void * new, void ** old)
{
    if (func != NULL) 
    { 
        GumInterceptorBeginTransactionFunc(magic);
        GumInterceptorReplaceFunc(magic, (gpointer)func, new, NULL, old);
        GumInterceptorEndTransactionFunc(magic);
    }
}

void InstantiateClientHooks(GumInterceptor *interceptor) {
    // Setup hooking
    magic = interceptor;
    void *hooking = dlopen("/usr/local/bin/ammonia/fridagum.dylib", RTLD_NOW | RTLD_GLOBAL);
    GumInterceptorReplaceFunc = dlsym(hooking, "gum_interceptor_replace");
    GumModuleFindExportByNameFunc = dlsym(hooking, "gum_module_find_export_by_name");
    GumInterceptorBeginTransactionFunc = dlsym(hooking, "gum_interceptor_begin_transaction");
    GumInterceptorEndTransactionFunc = dlsym(hooking, "gum_interceptor_end_transaction");

    symrez_t skylight = symrez_new("SkyLight");
    
    if (skylight != NULL) { 
        // Hooks the shadow image, and properties
        ClientHook(sr_resolve_symbol(skylight, "_WSWindowShadowWantsRenderAbove"), WantsRenderAbove, NULL); 
        ClientHook(sr_resolve_symbol(skylight, "__ZL28is_shadow_mask_nine_partableP9CGXWindow"), NinePartable, NULL); 
        ClientHook(sr_resolve_symbol(skylight, "_WSWindowSetHasActiveShadow"), ServerSetHasActiveShadowNew, &ServerSetHasActiveShadowOld); 
        ClientHook(sr_resolve_symbol(skylight, "__ZN8WSShadowC1EP11__IOSurface19WSShadowDescription"), ServerShadowSurfaceNew, &ServerShadowSurfaceOld); 
    }
}