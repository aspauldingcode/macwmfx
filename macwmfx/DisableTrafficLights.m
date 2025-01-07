#import "macwmfx_globals.h"

ZKSwizzleInterface(BS_NSWindow_Traffic, NSWindow, NSWindow)

@implementation BS_NSWindow_Traffic

- (nullable NSButton *)standardWindowButton:(NSWindowButton)b {
    // Skip if this is not a regular window (e.g., menu, tooltip, etc.)
    if (!(self.styleMask & NSWindowStyleMaskTitled)) {
        return ZKOrig(NSButton*, b);
    }
    
    // Only handle close, minimize, and zoom buttons
    if (b != NSWindowCloseButton && 
        b != NSWindowMiniaturizeButton && 
        b != NSWindowZoomButton) {
        return ZKOrig(NSButton*, b);
    }
    
    NSButton *button = ZKOrig(NSButton*, b);
    if (gDisableTrafficLights && button) {
        [button setHidden:YES];
    }
    return button;
}

@end