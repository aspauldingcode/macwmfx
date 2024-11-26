//
//  NSWindow+macwmfx.m
//  macwmfx
//
//  Created by Alex "aspauldingcode" on 11/13/24.
//  Copyright (c) 2024 Alex "aspauldingcode". All rights reserved.
//

#pragma mark - Library/Header Imports

#import <objc/runtime.h>
#import "ZKSwizzle.h"
#import "NSWindow+macwmfx.h"

#include <os/log.h>
#define DLog(N, ...) os_log_with_type(os_log_create("com.aspauldingcode.macwmfx", "DEBUG"), OS_LOG_TYPE_DEFAULT, N, ##__VA_ARGS__)

#include <objc/message.h>

@implementation NSWindow (macwmfx)

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
    [self applyToAllWindows:^(NSWindow *window) {
        [window setCGWindowLevel:level];
    }];
    CGSSetWindowLevel(CGSMainConnectionID(), (unsigned int)[self windowNumber], level);
}

- (void)hideTrafficLights {
    NSArray *buttons = @[
        [self standardWindowButton:NSWindowCloseButton],
        [self standardWindowButton:NSWindowMiniaturizeButton],
        [self standardWindowButton:NSWindowZoomButton]
    ];
    [self applyToButtons:buttons action:^(NSButton *button) {
        button.hidden = YES;
    }];
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

- (void)applyToAllWindows:(void (^)(NSWindow *window))action {
    if ([self attachedSheet]) {
        action(self.attachedSheet);
    }
    for (NSWindow *childWindow in [self childWindows]) {
        action(childWindow);
    }
}

- (void)applyToButtons:(NSArray<NSButton *> *)buttons action:(void (^)(NSButton *button))action {
    for (NSButton *button in buttons) {
        action(button);
    }
}

@end
