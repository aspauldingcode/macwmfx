#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>
#include <QuartzCore/QuartzCore.h>
#include <dlfcn.h>
#include <objc/runtime.h>

CALayer* (*_old_layer)(id self, SEL _cmd);
CALayer* replacement_layer(id self, SEL _cmd) {
    CALayer *orig = _old_layer(self, _cmd);
    [orig setBackgroundColor:NSColor.redColor.CGColor];
    return orig;
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

// Ammonia entry point
__attribute__((visibility("default"))) void LoadFunction(void *interceptor) { 
    // Hook NSView's layer method
    Class viewClass = NSClassFromString(@"NSView");
    if (viewClass != nil) {
        // Then hook the layer method
        HookObjcMethod(viewClass, @selector(layer), (IMP)replacement_layer, (void **)&_old_layer);
        
        NSLog(@"[INFO] NSView layer hooks installed");
    } else {
        NSLog(@"[ERROR] Failed to find NSView class");
    }
    
    NSLog(@"[INFO] Red background hook loaded successfully");
}