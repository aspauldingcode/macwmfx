#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>
#include <QuartzCore/QuartzCore.h>
#include <dlfcn.h>
#include <objc/runtime.h>
#include <stdarg.h>

// Objective-C hook storage
CALayer* (*_old_layer)(id self, SEL _cmd);

// C hook storage
void (*printf_old)(const char *, ...);

// Frida/Gum function pointers for C hooks
void (*GumInterceptorReplaceFunc)(void * self, void * function_address, void * replacement_function, void * replacement_data, void ** original_function);
void *(*GumModuleFindExportByNameFunc)(const char * module_name, const char * symbol_name);
void (*GumInterceptorBeginTransactionFunc)(void * self);
void (*GumInterceptorEndTransactionFunc)(void * self);

void * magic;

// Objective-C hook replacement functions
CALayer* replacement_layer(id self, SEL _cmd) {
    CALayer *orig = _old_layer(self, _cmd);
    [orig setBackgroundColor:NSColor.redColor.CGColor];
    return orig;
}

// C hook replacement functions
void printf_hook(const char *format, ...) {
    va_list args;
    va_start(args, format);

    printf_old("[HOOKED] ");
    vprintf(format, args);

    va_end(args);
}

// Helper function to hook Objective-C methods
void HookObjcMethod(Class class, SEL selector, IMP replacement, IMP *original) {
    Method method = class_getInstanceMethod(class, selector);
    if (method != NULL) {
        *original = method_setImplementation(method, replacement);
        NSLog(@"[HOOKED] Successfully hooked %@ method on %@", 
              NSStringFromSelector(selector), 
              NSStringFromClass(class));
    } else {
        NSLog(@"[ERROR] Failed to find method %@ in class %@", 
              NSStringFromSelector(selector), 
              NSStringFromClass(class));
    }
}

// Helper function to hook C functions using Frida/Gum
void HookCFunction(void * func, void * new, void ** old) {
    if (func != NULL) { 
        GumInterceptorBeginTransactionFunc(magic);
        GumInterceptorReplaceFunc(magic, func, new, NULL, old);
        GumInterceptorEndTransactionFunc(magic);
    }
}

// Ammonia entry point - unified hook loader
__attribute__((visibility("default"))) void LoadFunction(void *interceptor) { 
    NSLog(@"[INFO] macwmfx LoadFunction called - initializing hooks");
    
    // Setup C function hooking via Frida/Gum
    magic = interceptor;
    void *hooking = dlopen("/usr/local/bin/ammonia/fridagum.dylib", RTLD_NOW | RTLD_GLOBAL);
    if (hooking != NULL) {
        GumInterceptorReplaceFunc = dlsym(hooking, "gum_interceptor_replace");
        GumModuleFindExportByNameFunc = dlsym(hooking, "gum_module_find_export_by_name");
        GumInterceptorBeginTransactionFunc = dlsym(hooking, "gum_interceptor_begin_transaction");
        GumInterceptorEndTransactionFunc = dlsym(hooking, "gum_interceptor_end_transaction");
        
        // Hook C functions (example: printf)
        HookCFunction(printf, printf_hook, (void **)&printf_old);
        NSLog(@"[INFO] C function hooks initialized");
    } else {
        NSLog(@"[WARNING] Failed to load fridagum.dylib - C hooks disabled");
    }
    
    // Setup Objective-C method hooking
    Class viewClass = NSClassFromString(@"NSView");
    if (viewClass != nil) {
        // Hook the layer method for red background example
        HookObjcMethod(viewClass, @selector(layer), (IMP)replacement_layer, (void **)&_old_layer);
        NSLog(@"[INFO] NSView layer hooks installed");
    } else {
        NSLog(@"[ERROR] Failed to find NSView class");
    }
    
    NSLog(@"[INFO] macwmfx hook initialization complete");
}