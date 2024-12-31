// #import "macwmfx_globals.h"

// ZKSwizzleInterface(BS_NSWindow_TitleBar, NSWindow, NSWindow)

// @implementation BS_NSWindow_TitleBar

// - (void)makeKeyAndOrderFront:(id)sender {
//     ZKOrig(void, sender);
    
//     // Disable title bar if the setting is enabled
//     if (gDisableTitlebar) {
//         [self disableTitleBar];
//     }
// }

// - (void)disableTitleBar {
//     NSWindow *window = (NSWindow *)self;
//     window.titlebarAppearsTransparent = YES;
//     window.titleVisibility = NSWindowTitleHidden;
//     window.styleMask |= NSWindowStyleMaskFullSizeContentView;
//     window.contentView.wantsLayer = YES; // Ensure contentView is layer-backed
// }

// @end 