#import "macwmfx_globals.h"

ZKSwizzleInterface(BS_NSWindow_TitleBar, NSWindow, NSWindow)

@implementation BS_NSWindow_TitleBar

- (void)makeKeyAndOrderFront:(id)sender {
    ZKOrig(void, sender);
    [self forceClassicTitleBar];
}

- (void)forceClassicTitleBar {
    NSWindow *window = (NSWindow *)self;
    // Remove modern styles
    window.titlebarAppearsTransparent = NO;
    window.titleVisibility = NSWindowTitleVisible;
    window.styleMask &= ~NSWindowStyleMaskFullSizeContentView;
    window.styleMask &= ~NSWindowStyleMaskUnifiedTitleAndToolbar;
    
    // Ensure classic titlebar is visible
    window.styleMask |= NSWindowStyleMaskTitled;
    
    if (@available(macOS 11.0, *)) {
        window.toolbarStyle = NSWindowToolbarStyleExpanded;
    }
}

@end 