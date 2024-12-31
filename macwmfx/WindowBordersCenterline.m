// #import "macwmfx_globals.h"

// @interface WindowBordersCenterline : NSObject
// @end

// @implementation WindowBordersCenterline

// + (void)load {
//     // Nothing needed here since we just want the swizzle
// }

// @end

// ZKSwizzleInterface(BS_NSWindow_BordersCenterline, NSWindow, NSWindow)

// @implementation BS_NSWindow_BordersCenterline

// - (void)makeKeyAndOrderFront:(id)sender {
//     ZKOrig(void, sender);
    
//     if (!gOutlineEnabled || ![gOutlineType isEqualToString:@"centerline"]) return;
    
//     NSWindow *window = (NSWindow *)self;
//     NSView *frameView = [window.contentView superview];
//     if (!frameView) return;
    
//     frameView.wantsLayer = YES;
//     frameView.layer.borderWidth = gOutlineWidth;
//     frameView.layer.cornerRadius = gOutlineCornerRadius;
//     frameView.layer.borderColor = gOutlineActiveColor.CGColor;
// }

// - (void)becomeKeyWindow {
//     ZKOrig(void);
    
//     if (!gOutlineEnabled || ![gOutlineType isEqualToString:@"centerline"]) return;
    
//     NSView *frameView = [self.contentView superview];
//     frameView.layer.borderColor = gOutlineActiveColor.CGColor;
// }

// - (void)resignKeyWindow {
//     ZKOrig(void);
    
//     if (!gOutlineEnabled || ![gOutlineType isEqualToString:@"centerline"]) return;
    
//     NSView *frameView = [self.contentView superview];
//     frameView.layer.borderColor = gOutlineInactiveColor.CGColor;
// }

// @end