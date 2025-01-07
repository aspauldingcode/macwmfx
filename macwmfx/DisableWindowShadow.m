#import "macwmfx_globals.h"

ZKSwizzleInterface(BS_NSWindow_Shadow, NSWindow, NSWindow)

@implementation BS_NSWindow_Shadow

- (void)makeKeyAndOrderFront:(id)sender {
    ZKOrig(void, sender);
    
    // Skip if this is not a regular window (e.g., menu, tooltip, etc.)
    if (!(self.styleMask & NSWindowStyleMaskTitled)) return;
    
    if (gDisableWindowShadow) {
        [(NSWindow *)self setHasShadow:NO];
    }
}

- (void)setHasShadow:(BOOL)hasShadow {
    // Skip if this is not a regular window (e.g., menu, tooltip, etc.)
    if (!(self.styleMask & NSWindowStyleMaskTitled)) {
        ZKOrig(void, hasShadow);
        return;
    }
    
    ZKOrig(void, gDisableWindowShadow ? NO : hasShadow);
}

@end