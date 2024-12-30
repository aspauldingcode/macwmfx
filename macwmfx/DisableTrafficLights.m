#import <AppKit/AppKit.h>
#import "ZKSwizzle.h"
#import "macwmfx_globals.h"

ZKSwizzleInterface(BS_NSWindow, NSWindow, NSResponder)

@implementation BS_NSWindow

- (nullable NSButton *)standardWindowButton:(NSWindowButton)b {
    NSButton *button = ZKOrig(NSButton*, b);
    if (gDisableTrafficLights && button) {
        button.hidden = YES;
    }
    return button;
}

@end