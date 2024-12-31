// #import "macwmfx_globals.h"

// ZKSwizzleInterface(BS_NSWindow_Shadow, NSWindow, NSWindow)

// @implementation BS_NSWindow_Shadow

// - (void)makeKeyAndOrderFront:(id)sender {
//     ZKOrig(void, sender);
//     if (gDisableWindowShadow) {
//         [(NSWindow *)self setHasShadow:NO];
//     }
// }

// - (void)setHasShadow:(BOOL)hasShadow {
//     ZKOrig(void, gDisableWindowShadow ? NO : hasShadow);
// }

// @end