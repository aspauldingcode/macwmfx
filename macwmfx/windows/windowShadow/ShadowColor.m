//
//  ShadowColor.m
//  macwmfx
//
//  Created by Alex "aspauldingcode" on 11/13/24.
//  Copyright (c) 2024 Alex "aspauldingcode". All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "../../headers/macwmfx_globals.h"
#import <objc/message.h>

// ZKSwizzleInterface(BS_NSWindow_ShadowColor, NSWindow, NSWindow)

// @implementation BS_NSWindow_ShadowColor

// - (void)makeKeyAndOrderFront:(id)sender {
//     ZKOrig(void, sender);
//     [self updateShadowColor];
// }

// - (void)becomeKeyWindow {
//     ZKOrig(void);
//     [self updateShadowColor];
// }

// - (void)orderFront:(id)sender {
//     ZKOrig(void, sender);
//     [self updateShadowColor];
// }

// - (void)updateShadowColor {
//     // Skip if shadow customization is disabled
//     if (!gShadowConfig.color) return;
    
//     // Force shadow to be enabled if we're customizing it
//     [(NSWindow *)self setHasShadow:YES];
    
//     // Try to access the window's core shadow
//     if ([self respondsToSelector:@selector(_getCoreShadow)]) {
//         id coreShadow = ((id (*)(id, SEL))objc_msgSend)(self, @selector(_getCoreShadow));
//         if (coreShadow) {
//             // Try setting the shadow color directly on the core shadow
//             if ([coreShadow respondsToSelector:@selector(setShadowColor:)]) {
//                 ((void (*)(id, SEL, CGColorRef))objc_msgSend)(coreShadow, @selector(setShadowColor:), gShadowConfig.color.CGColor);
//             }
            
//             // Force a shadow update
//             [(NSWindow *)self invalidateShadow];
//             if ([self respondsToSelector:@selector(_invalidateCoreShadow)]) {
//                 ((void (*)(id, SEL))objc_msgSend)(self, @selector(_invalidateCoreShadow));
//             }
//         }
//     }
// }

// - (void)setHasShadow:(BOOL)hasShadow {
//     // Only force shadow to be enabled if we're customizing the color
//     if (gShadowConfig.color) {
//         ZKOrig(void, YES);
//     } else {
//         ZKOrig(void, hasShadow);
//     }
// }

// @end
