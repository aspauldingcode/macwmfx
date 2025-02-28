//
//  userhooks.c
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

#include "SymRez/SymRez.h"
// #include "heights.h"
// #include "frida-gum.h"

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
    CGFloat leftInset = insets;
    CGFloat rightInset = insets;
    CGFloat topInset = insets;
    CGFloat bottomInset = insets;
    
    CGSize imageSize = CGSizeMake(CGImageGetWidth(image), CGImageGetHeight(image));
    
    // Draw top left corner
    CGContextDrawImage(context, CGRectMake(rect.origin.x, rect.origin.y, leftInset, topInset), CGImageCreateWithImageInRect(image, CGRectMake(0, imageSize.height - topInset, leftInset, topInset)));
    
    // Draw top edge
    CGContextDrawImage(context, CGRectMake(rect.origin.x + leftInset, rect.origin.y, rect.size.width - leftInset - rightInset, topInset), CGImageCreateWithImageInRect(image, CGRectMake(leftInset, imageSize.height - topInset, imageSize.width - leftInset - rightInset, topInset)));
    
    // Draw top right corner
    CGContextDrawImage(context, CGRectMake(rect.origin.x + rect.size.width - rightInset, rect.origin.y, rightInset, topInset), CGImageCreateWithImageInRect(image, CGRectMake(imageSize.width - rightInset, imageSize.height - topInset, rightInset, topInset)));
    
    // Draw left edge
    CGContextDrawImage(context, CGRectMake(rect.origin.x, rect.origin.y + topInset, leftInset, rect.size.height - topInset - bottomInset), CGImageCreateWithImageInRect(image, CGRectMake(0, topInset, leftInset, imageSize.height - topInset - bottomInset)));
    
    // Draw center
    CGContextDrawImage(context, CGRectMake(rect.origin.x + leftInset, rect.origin.y + topInset, rect.size.width - leftInset - rightInset, rect.size.height - topInset - bottomInset), CGImageCreateWithImageInRect(image, CGRectMake(leftInset, topInset, imageSize.width - leftInset - rightInset, imageSize.height - topInset - bottomInset)));
    
    // Draw right edge
    CGContextDrawImage(context, CGRectMake(rect.origin.x + rect.size.width - rightInset, rect.origin.y + topInset, rightInset, rect.size.height - topInset - bottomInset), CGImageCreateWithImageInRect(image, CGRectMake(imageSize.width - rightInset, topInset, rightInset, imageSize.height - topInset - bottomInset)));
    
    // Draw bottom left corner
    CGContextDrawImage(context, CGRectMake(rect.origin.x, rect.origin.y + rect.size.height - bottomInset, leftInset, bottomInset), CGImageCreateWithImageInRect(image, CGRectMake(0, 0, leftInset, bottomInset)));
    
    // Draw bottom edge
    CGContextDrawImage(context, CGRectMake(rect.origin.x + leftInset, rect.origin.y + rect.size.height - bottomInset, rect.size.width - leftInset - rightInset, bottomInset), CGImageCreateWithImageInRect(image, CGRectMake(leftInset, 0, imageSize.width - leftInset - rightInset, bottomInset)));
    
    // Draw bottom right corner
    CGContextDrawImage(context, CGRectMake(rect.origin.x + rect.size.width - rightInset, rect.origin.y + rect.size.height - bottomInset, rightInset, bottomInset), CGImageCreateWithImageInRect(image, CGRectMake(imageSize.width - rightInset, 0, rightInset, bottomInset)));
}

CGImageRef shadow_png = NULL; 
long ServerShadowSurfaceNew(void * shadow_ptr /* WSShadow:: */, void * param_1,void * param_2)
{
    if (!shadow_png)
        shadow_png = ImageFromFile("/Library/wsfun/shadow.png");

    // Create a new iOSurface
    long k = ServerShadowSurfaceOld(shadow_ptr, param_1, param_2);
    struct ServerShadow * shadow = (struct ServerShadow *)shadow_ptr;

    IOSurfaceLock(shadow->surface, 0, NULL);
    int width = IOSurfaceGetWidth(shadow->surface);
    int height = IOSurfaceGetHeight(shadow->surface);

    // Create a bitmap context for the surface
    CGContextRef context = CGBitmapContextCreate(IOSurfaceGetBaseAddress(shadow->surface),
                                                 width,
                                                 height,
                                                 8, // bits per component
                                                 IOSurfaceGetBytesPerRow(shadow->surface),
                                                 CGColorSpaceCreateDeviceRGB(),
                                                 kCGImageAlphaPremultipliedLast);

    bool WindowHideShadow = true;
    bool WindowDecorations = true;

    if (WindowHideShadow) {
        CGContextClearRect(context, CGRectMake(0, 0, width, height));
    }

    if (WindowDecorations) {
        DrawNineSlice(context, shadow_png, CGRectMake(0, 0, width, height), 19); // Example insets)
        //CGContextClearRect(context, CGRectMake(0, 0, width, height)); // final clear of the REAL window rect.
    }
    
    CGContextFlush(context);
    CGContextRelease(context);

    SwapRedBlue(shadow->surface);
    // Return the iOSurface
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
    return true;
}

void *magic;
void (*GumInterceptorReplaceFunc)(void * self, void * function_address, void * replacement_function, void * replacement_data, void ** original_function);
void *(*GumModuleFindExportByNameFunc)(const char * module_name, const char * symbol_name);
void (*GumInterceptorBeginTransactionFunc)(void * self);
void (*GumInterceptorEndTransactionFunc)(void * self);

void ClientHook(void * func, void * new, void ** old)
{
    if (func != NULL) 
    { 
        GumInterceptorBeginTransactionFunc(magic);
        GumInterceptorReplaceFunc(magic, (void *)func, new, NULL, old);
        GumInterceptorEndTransactionFunc(magic);
    }
}

void InstantiateClientHooks(void *interceptor) {
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

        // Menubar
        // ClientHook(sr_resolve_symbol(skylight, "__ZL40configure_menu_bar_layers_for_backgroundP17PKGMenuBarContextb"), MenubarLayersNew, &MenubarLayersOld); // Needs fixup on sonoma
        // ClientHook(sr_resolve_symbol(skylight, "__ZL25menu_bar_bounds_for_spaceP19PKGManagedMenuSpace"), HeightNew, &HeightOld); 
        // ClientHook(sr_resolve_symbol(skylight, "_SLSGetDisplayMenubarHeight"), ClientRenderHeightNew, NULL);
    }
}