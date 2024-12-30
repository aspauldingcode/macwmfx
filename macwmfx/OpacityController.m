//
//  WindowTransparencyController.m
//  AfloatX
//
//  Created by j on 12/6/19.
//  Copyright © 2019 j. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "ZKSwizzle.h"
#import "macwmfx_globals.h"

@interface OpacityController : NSObject
+ (instancetype)sharedInstance;
@end

@implementation OpacityController

+ (void)load {
    // Initialize the swizzle when the class is loaded
    [self sharedInstance];
}

+ (instancetype)sharedInstance {
    static OpacityController *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

@end

ZKSwizzleInterface(BS_NSWindow_Opacity, NSWindow, NSWindow)

@implementation BS_NSWindow_Opacity

- (void)makeKeyAndOrderFront:(id)sender {
    ZKOrig(void, sender);
    [self updateWindowOpacity];
}

- (void)updateWindowOpacity {
    // Ensure transparency value is within valid range (0.1 to 1.0)
    CGFloat opacity = MAX(0.1, MIN(1.0, gTransparency));
    
    NSWindow *window = (NSWindow *)self;
    window.alphaValue = opacity;
    
    // Enable transparency if opacity is less than 1.0
    if (opacity < 1.0) {
        window.opaque = NO;
        window.backgroundColor = [[NSColor windowBackgroundColor] colorWithAlphaComponent:opacity];
    } else {
        window.opaque = YES;
        window.backgroundColor = [NSColor windowBackgroundColor];
    }
}

@end