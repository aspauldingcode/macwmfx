#import <AppKit/AppKit.h>
#import "ZKSwizzle.h"
#import "macwmfx_globals.h"

ZKSwizzleInterface(BS_NSWindow_Resize, NSWindow, NSWindow)

@implementation BS_NSWindow_Resize

- (void)makeKeyAndOrderFront:(id)sender {
    ZKOrig(void, sender);
    
    // Disable resize constraints if the setting is enabled
    if (gDisableWindowSizeConstraints) {
        [self disableResizeConstraints];
    }
}

- (void)disableResizeConstraints {
    // Directly use self as NSWindow instead of accessing a private ivar
    NSWindow *window = (NSWindow *)self;
    
    // Enable resizing and remove constraints
    window.styleMask |= NSWindowStyleMaskResizable;
    [window setMinSize:NSMakeSize(0.0, 0.0)];
    [window setMaxSize:NSMakeSize(CGFLOAT_MAX, CGFLOAT_MAX)];
}

@end