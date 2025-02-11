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

// Global variables
bool WindowHideShadow = false;
bool WindowDecorations = true;
int __height = 50;
bool MenubarGraphic = true;

// Global variables for original function pointers
CGRect (*HeightOld)() = NULL;
CGError (*ServerSetHasActiveShadowOld)(long param_1, uint param_2) = NULL;
long (*ServerShadowSurfaceOld)(void *shadow_ptr, void *param_1, void *param_2) = NULL;
void (*MenubarLayersOld)(void *param_1, bool param_2) = NULL;

// Function prototypes
CGImageRef ImageFromFile(const char *filePath);
void MenubarLayersNew(void *param_1, bool param_2);
CGRect HeightNew();
void ClientRenderHeightNew(int did, int *height);
long ServerShadowSurfaceNew(void *shadow_ptr, void *param_1, void *param_2);
CGError ServerSetHasActiveShadowNew(long param_1, uint param_2);
bool WantsRenderAbove();
bool NinePartable();
void InstantiateClientHooks();
void ClientHook(void *func, void *new, void **old);
void DrawNineSlice(CGContextRef context, CGImageRef image, CGRect rect, int insets);
void SwapRedBlue(IOSurfaceRef surface);

// Function implementations
CGImageRef ImageFromFile(const char *filePath) {
    CGDataProviderRef dataProvider = CGDataProviderCreateWithFilename(filePath);
    return CGImageCreateWithPNGDataProvider(dataProvider, NULL, NO, kCGRenderingIntentDefault);
}

void MenubarLayersNew(void *param_1, bool param_2) {
    if (MenubarLayersOld) {
        MenubarLayersOld(param_1, param_2);
    }

    if (MenubarGraphic) {
        // ARC-compatible pointer casting
        void **rawLayers = (void **)param_1;
        CALayer *layer_one = (__bridge CALayer *)rawLayers[0x10/sizeof(void*)];
        CALayer *layer_two = (__bridge CALayer *)rawLayers[0x18/sizeof(void*)];

        layer_one.contents = (__bridge id)ImageFromFile("/Library/wsfun/menubar.png");
        layer_two.contents = (__bridge id)ImageFromFile("/Library/wsfun/menubar.png");
    }
}

CGRect HeightNew() {
    if (HeightOld) {
        CGRect orig = HeightOld();
        orig.size.height = __height;
        return orig;
    }
    return CGRectZero;
}

void ClientRenderHeightNew(int did, int *height) {
    (void)did; // Mark 'did' as unused
    if (height) {
        *height = __height;
    }
}

struct ServerShadow {
    IOSurfaceRef surface;
    // Other members...
};

void SwapRedBlue(IOSurfaceRef surface) {
    if (!surface) {
        return;
    }

    uint32_t width = (uint32_t)IOSurfaceGetWidth(surface);
    uint32_t height = (uint32_t)IOSurfaceGetHeight(surface);
    size_t bytesPerElement = IOSurfaceGetBytesPerElement(surface);
    size_t bytesPerRow = IOSurfaceGetBytesPerRow(surface);
    void *baseAddress = IOSurfaceGetBaseAddress(surface);

    for (uint32_t y = 0; y < height; y++) {
        for (uint32_t x = 0; x < width; x++) {
            size_t offset = y * bytesPerRow + x * bytesPerElement;
            uint8_t *pixel = ((uint8_t *)baseAddress) + offset;
            uint8_t temp = pixel[0];  // Store red channel temporarily
            pixel[0] = pixel[2];      // Red channel becomes blue
            pixel[2] = temp;          // Blue channel becomes red
        }
    }
}

void DrawNineSlice(CGContextRef context, CGImageRef image, CGRect rect, int insets) {
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
long ServerShadowSurfaceNew(void *shadow_ptr, void *param_1, void *param_2) {
    if (!shadow_png) {
        shadow_png = ImageFromFile("/Library/wsfun/shadow.png");
    }

    long k = ServerShadowSurfaceOld ? ServerShadowSurfaceOld(shadow_ptr, param_1, param_2) : 0;
    struct ServerShadow *shadow = (struct ServerShadow *)shadow_ptr;

    if (shadow && shadow->surface) {
        IOSurfaceLock(shadow->surface, 0, NULL);
        int width = IOSurfaceGetWidth(shadow->surface);
        int height = IOSurfaceGetHeight(shadow->surface);

        CGContextRef context = CGBitmapContextCreate(IOSurfaceGetBaseAddress(shadow->surface),
                                                     width,
                                                     height,
                                                     8,
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
    }

    return k;
}

CGError ServerSetHasActiveShadowNew(long param_1, uint param_2) {
    (void)param_2; // Mark as unused
    return ServerSetHasActiveShadowOld ? ServerSetHasActiveShadowOld(param_1, 0) : kCGErrorSuccess;
}

bool WantsRenderAbove() {
    return false;
}

bool NinePartable() {
    return true;
}

void ClientHook(void *func, void *new, void **old) {
    if (func && new) {
        *old = func; // Save the original function pointer
        // Replace the original function with the new function
        // This is platform-specific and may require additional work
    }
}

void InstantiateClientHooks() {
    // Resolve symbols and hook functions manually
    void *skylight = dlopen("/System/Library/PrivateFrameworks/SkyLight.framework/SkyLight", RTLD_NOW);
    if (skylight) {
        ClientHook(dlsym(skylight, "_WSWindowShadowWantsRenderAbove"), WantsRenderAbove, NULL);
        ClientHook(dlsym(skylight, "__ZL28is_shadow_mask_nine_partableP9CGXWindow"), NinePartable, NULL);
        ClientHook(dlsym(skylight, "_WSWindowSetHasActiveShadow"), ServerSetHasActiveShadowNew, (void **)&ServerSetHasActiveShadowOld);
        ClientHook(dlsym(skylight, "__ZN8WSShadowC1EP11__IOSurface19WSShadowDescription"), ServerShadowSurfaceNew, (void **)&ServerShadowSurfaceOld);

        // Menubar
        // ClientHook(dlsym(skylight, "__ZL40configure_menu_bar_layers_for_backgroundP17PKGMenuBarContextb"), MenubarLayersNew, &MenubarLayersOld);
        // ClientHook(dlsym(skylight, "__ZL25menu_bar_bounds_for_spaceP19PKGManagedMenuSpace"), HeightNew, &HeightOld);
        // ClientHook(dlsym(skylight, "_SLSGetDisplayMenubarHeight"), ClientRenderHeightNew, NULL);
    }
}