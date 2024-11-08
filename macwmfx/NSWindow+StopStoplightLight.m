//
//  NSWindow+StopStoplightLight.m
//  StopStoplightLight
//
//  Created by Brian "Shishkabibal" on 6/25/24.
//  Copyright (c) 2024 Brian "Shishkabibal". All rights reserved.
//

#pragma mark - Library/Header Imports

#import <objc/runtime.h>
#import "ZKSwizzle.h"
#import "NSWindow+StopStoplightLight.h"

#include <os/log.h>
#define DLog(N, ...) os_log_with_type(os_log_create("com.shishkabibal.StopStoplightLight", "DEBUG"), OS_LOG_TYPE_DEFAULT, N, ##__VA_ARGS__)

#include <objc/message.h>

@implementation NSWindow (StopStoplightLight)

+ (NSWindow *)topWindow {
    NSWindow *window = [NSApp mainWindow];
    if (!window) {
        window = ((NSWindow* (*)(id, SEL))objc_msgSend)(NSApp, sel_getUid("frontWindow"));
    }
    return window;
}

- (BOOL)isSystemApp {
    // Implement the method logic here
    return NO; // Placeholder return value
}

// Declare private API functions
extern void CGSSetWindowLevel(int connection, int windowNumber, int level);
extern int CGSMainConnectionID(void);

- (void)setCGWindowLevel:(CGWindowLevel)level {
    if ([self attachedSheet]) {
        [self.attachedSheet setCGWindowLevel:level];
    }
    
    for (NSWindow *childWindow in [self childWindows]) {
        [childWindow setCGWindowLevel:level];
    }
    
    CGSSetWindowLevel(CGSMainConnectionID(), (unsigned int)[self windowNumber], level);
}

- (void)hideTrafficLights {
    [self hideButton:[self standardWindowButton:NSWindowCloseButton]];
    [self hideButton:[self standardWindowButton:NSWindowMiniaturizeButton]];
    [self hideButton:[self standardWindowButton:NSWindowZoomButton]];
}

- (void)modifyTitlebarAppearance {
    self.titlebarAppearsTransparent = YES;
    self.titleVisibility = NSWindowTitleHidden;
    self.styleMask |= NSWindowStyleMaskFullSizeContentView;
    self.contentView.wantsLayer = YES; // Ensure contentView is layer-backed
}

- (void)makeResizableToAnySize {
    self.styleMask |= NSWindowStyleMaskResizable;
    [self setMinSize:NSMakeSize(0.0, 0.0)];
    [self setMaxSize:NSMakeSize(CGFLOAT_MAX, CGFLOAT_MAX)];
}

- (void)hideButton:(NSButton *)button {
    button.hidden = YES;
}

@end
