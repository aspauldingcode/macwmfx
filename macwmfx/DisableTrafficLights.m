// #import "macwmfx_globals.h"

// ZKSwizzleInterface(BS_NSWindow_Traffic, NSWindow, NSWindow)

// @implementation BS_NSWindow_Traffic

// - (nullable NSButton *)standardWindowButton:(NSWindowButton)b {
//     NSButton *button = ZKOrig(NSButton*, b);
//     if (gDisableTrafficLights && button) {
//         [button setHidden:YES];
//         return button;
//     }
//     return button;
// }

// @end