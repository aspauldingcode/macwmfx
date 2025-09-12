//
//  HookUtil.m
//  RibbonBar
//
//  Created by bedtime on 5/18/25.
//

#import "RibbonBar.h"

#include <objc/runtime.h>
#include <QuartzCore/QuartzCore.h>
#include <CoreGraphics/CoreGraphics.h>
#include <Foundation/Foundation.h>
#include <stdio.h>
#include <dlfcn.h>

void HookFunc(void* func, void* newFunc, void** oldFunc) {
    if (func != 0x55) {
        GumInterceptorBeginTransactionFunc(gHook);
        GumInterceptorReplaceFunc(gHook, (void *)(func), newFunc, NULL, oldFunc);
        GumInterceptorEndTransactionFunc(gHook);
    }
}

void SwizzleMethod(Class cls, SEL originalSelector, SEL swizzledSelector, id (**originalImplementation)(id, SEL)) {
    Method originalMethod = class_getInstanceMethod(cls, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(cls, swizzledSelector);

    BOOL didAddMethod = class_addMethod(cls,
                                        originalSelector,
                                        method_getImplementation(swizzledMethod),
                                        method_getTypeEncoding(swizzledMethod));
    
    if (didAddMethod) {
        class_replaceMethod(cls,
                            swizzledSelector,
                            method_getImplementation(originalMethod),
                            method_getTypeEncoding(originalMethod));
    } else {
        // Store the original implementation in the appropriate function pointer
        if (originalImplementation) {
            *originalImplementation = (id (*)(id, SEL))method_getImplementation(originalMethod);
        }
        
        // Swap implementations
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

void AddHook(Class class, SEL originalSelector, SEL swizzledSelector, IMP implementation, Method *originalMethodStorage, BOOL isClassMethod) {
    if (class) {
        Method originalMethod = isClassMethod ? class_getClassMethod(class, originalSelector) : class_getInstanceMethod(class, originalSelector);
        if (originalMethod) {
            Class targetClass = isClassMethod ? object_getClass(class) : class;
            class_addMethod(targetClass,
                            swizzledSelector,
                            implementation,
                            method_getTypeEncoding(originalMethod));
            SwizzleMethod(targetClass, originalSelector, swizzledSelector, originalMethodStorage);
        }
    }
}
