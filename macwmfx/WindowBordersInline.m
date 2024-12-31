// #import "macwmfx_globals.h"

// @interface WindowBordersInline : NSObject
// @end

// @implementation WindowBordersInline

// + (void)load {
//     // Nothing needed here since we just want the swizzle
// }

// @end

// ZKSwizzleInterface(BS_NSWindow_BordersInline, NSWindow, NSWindow)

// @implementation BS_NSWindow_BordersInline

// - (void)makeKeyAndOrderFront:(id)sender {
//     ZKOrig(void, sender);
    
//     if (!gOutlineEnabled || ![gOutlineType isEqualToString:@"inline"]) return;
    
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
    
//     if (!gOutlineEnabled || ![gOutlineType isEqualToString:@"inline"]) return;
    
//     NSView *frameView = [self.contentView superview];
//     frameView.layer.borderColor = gOutlineActiveColor.CGColor;
// }

// - (void)resignKeyWindow {
//     ZKOrig(void);
    
//     if (!gOutlineEnabled || ![gOutlineType isEqualToString:@"inline"]) return;
    
//     NSView *frameView = [self.contentView superview];
//     frameView.layer.borderColor = gOutlineInactiveColor.CGColor;
// }

// @end