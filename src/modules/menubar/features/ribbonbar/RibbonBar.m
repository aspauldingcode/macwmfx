//
//  RibbonBar.m
//  RibbonBar
//
//  Created by bedtime on 5/17/25.
//

#import "RibbonBar.h"
#import "RibbonBarShared.h"

#include <AppKit/AppKit.h>
#include <objc/runtime.h>
#include <QuartzCore/QuartzCore.h>
#include <CoreGraphics/CoreGraphics.h>
#include <Foundation/Foundation.h>
#include <stdio.h>
#include <dlfcn.h>

#import "NSThemeFrame.h"

#define kRibbonInset 5.0
#define kRibbonHeight 22.0
#define kRibbonPadding 10.0

// Extern declarations for ribbon bar symbols implemented in macwmfx_server.m
extern void DisplayMenuAsContextual(NSMenu *menu, NSView *view, NSPoint location);
extern CGFloat FindVisualEffectViewSecondOrHighestX(NSView *parentView);
extern void ForceTitlebar(id self, SEL _cmd, NSWindowStyleMask style);
extern NSView* TitlebarContainerView(NSView *self, SEL _cmd);

void (*_ForceTitlebarOld)(id self, SEL _cmd, NSWindowStyleMask styleMask);
NSView * (*_TitlebarContainerViewOld)(id self, SEL _cmd);

// Remove the implementations of these functions - they are now in macwmfx_server.m
// Only keep the function pointer declarations above

void * gHook;

GumInterceptorReplaceFuncType GumInterceptorReplaceFunc;
GumInterceptorBeginTransactionFuncType GumInterceptorBeginTransactionFunc;
GumInterceptorEndTransactionFuncType GumInterceptorEndTransactionFunc;

extern
void AddHook(Class class, SEL originalSelector, SEL swizzledSelector, IMP implementation, Method *originalMethodStorage, BOOL isClassMethod);
