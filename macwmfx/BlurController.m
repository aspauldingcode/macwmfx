//#import <AppKit/AppKit.h>
//#import "ZKSwizzle.h"

//@interface BlurController : NSObject
//@end

//@implementation BlurController

//+ (void)load {
//    // Nothing needed here since we just want the swizzle
//}

//@end

//ZKSwizzleInterface(BS_NSWindow_Blur, NSWindow, NSWindow)

//@implementation BS_NSWindow_Blur

//- (void)makeKeyAndOrderFront:(id)sender {
//    ZKOrig(void, sender);
//    
//    // Directly use self as NSWindow instead of accessing a private ivar
//    NSWindow *window = (NSWindow *)self;
//    window.contentView.wantsLayer = YES;
//    window.backgroundColor = [NSColor clearColor];
//    window.opaque = NO;
//    
//    // Simple blur effect using native AppKit
//    NSVisualEffectView *blurView = [[NSVisualEffectView alloc] initWithFrame:window.contentView.bounds];
//    blurView.material = NSVisualEffectMaterialWindowBackground;
//    blurView.blendingMode = NSVisualEffectBlendingModeBehindWindow;
//    blurView.state = NSVisualEffectStateActive;
//    blurView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
//    
//    // Remove any existing blur views first
//    for (NSView *subview in window.contentView.subviews) {
//        if ([subview isKindOfClass:[NSVisualEffectView class]]) {
//            [subview removeFromSuperview];
//        }
//    }
//    
//    [window.contentView addSubview:blurView positioned:NSWindowBelow relativeTo:nil];
//}

//@end