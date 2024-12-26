//
//  WindowTransparencyController.m
//  AfloatX
//
//  Created by j on 12/6/19.
//  Copyright © 2019 j. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "ZKSwizzle.h"

@interface OpacityController : NSObject
@end

@implementation OpacityController

+ (void)load {
    // Nothing needed here since we just want the swizzle
}

@end

ZKSwizzleInterface(BS_NSWindow_Opacity, NSWindow, NSWindow)

@implementation BS_NSWindow_Opacity

- (void)makeKeyAndOrderFront:(id)sender {
    ZKOrig(void, sender);
    
    // Set default opacity for all windows
    NSWindow *window = (NSWindow *)self;
    [window setAlphaValue:0.95];
}

- (void)setAlphaValue:(CGFloat)alpha {
    // Ensure opacity stays within bounds
    CGFloat boundedAlpha = MAX(0.1, MIN(alpha, 1.0));
    ZKOrig(void, boundedAlpha);
}

@end