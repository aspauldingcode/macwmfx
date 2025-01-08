//
//  ShadowColor.m
//  macwmfx
//
//  Created by Alex "aspauldingcode" on 11/13/24.
//  Copyright (c) 2024 Alex "aspauldingcode". All rights reserved.
//

#import "macwmfx_globals.h"
#import <objc/message.h>

ZKSwizzleInterface(BS_NSWindow_Shadow, NSWindow, NSWindow)

@implementation BS_NSWindow_Shadow

- (void)makeKeyAndOrderFront:(id)sender {
    ZKOrig(void, sender);
    [self updateShadowColor];
}

- (void)becomeKeyWindow {
    ZKOrig(void);
    [self updateShadowColor];
}

- (void)orderFront:(id)sender {
    ZKOrig(void, sender);
    [self updateShadowColor];
}

- (void)updateShadowColor {
    // Force shadow to be enabled
    [(NSWindow *)self setHasShadow:YES];
    
    // Try to access the window's core shadow
    if ([self respondsToSelector:@selector(_getCoreShadow)]) {
        id coreShadow = ((id (*)(id, SEL))objc_msgSend)(self, @selector(_getCoreShadow));
        if (coreShadow) {
            CGColorRef yellowColor = CGColorCreateGenericRGB(1.0, 1.0, 0.0, 0.8);
            
            // Try setting the shadow color directly on the core shadow
            if ([coreShadow respondsToSelector:@selector(setShadowColor:)]) {
                ((void (*)(id, SEL, CGColorRef))objc_msgSend)(coreShadow, @selector(setShadowColor:), yellowColor);
            }
            
            // Release the CGColor
            CGColorRelease(yellowColor);
            
            // Force a shadow update
            [(NSWindow *)self invalidateShadow];
            if ([self respondsToSelector:@selector(_invalidateCoreShadow)]) {
                ((void (*)(id, SEL))objc_msgSend)(self, @selector(_invalidateCoreShadow));
            }
        }
    }
}

- (void)setHasShadow:(BOOL)hasShadow {
    // Always keep shadow enabled
    ZKOrig(void, YES);
}

@end
