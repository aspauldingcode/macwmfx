//
//  WindowBordersOutline.m
//  macwmfx
//
//  Created by Alex "aspauldingcode" on 11/13/24.
//  Copyright (c) 2024 Alex "aspauldingcode". All rights reserved.
//

#import "macwmfx_globals.h"

@interface WindowBordersOutline : NSObject
@end

@implementation WindowBordersOutline

+ (void)load {
    // Nothing needed here since we just want the swizzle
}

@end

ZKSwizzleInterface(BS_NSWindow_BordersOutline, NSWindow, NSWindow)

@implementation BS_NSWindow_BordersOutline

- (void)makeKeyAndOrderFront:(id)sender {
    ZKOrig(void, sender);
    
    if (!gOutlineEnabled || ![gOutlineType isEqualToString:@"outline"]) return;
    
    NSWindow *window = (NSWindow *)self;
    NSView *frameView = [window.contentView superview];
    if (!frameView) return;
    
    frameView.wantsLayer = YES;
    frameView.layer.borderWidth = gOutlineWidth;
    frameView.layer.cornerRadius = gOutlineCornerRadius;
    frameView.layer.borderColor = gOutlineActiveColor.CGColor;
}

- (void)becomeKeyWindow {
    ZKOrig(void);
    
    if (!gOutlineEnabled || ![gOutlineType isEqualToString:@"outline"]) return;
    
    NSView *frameView = [self.contentView superview];
    frameView.layer.borderColor = gOutlineActiveColor.CGColor;
}

- (void)resignKeyWindow {
    ZKOrig(void);
    
    if (!gOutlineEnabled || ![gOutlineType isEqualToString:@"outline"]) return;
    
    NSView *frameView = [self.contentView superview];
    frameView.layer.borderColor = gOutlineInactiveColor.CGColor;
}

@end