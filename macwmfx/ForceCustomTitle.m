#import "macwmfx_globals.h"

ZKSwizzleInterface(BS_NSWindow_TitleBar, NSWindow, NSWindow)

@implementation BS_NSWindow_TitleBar

- (void)makeKeyAndOrderFront:(id)sender {
    ZKOrig(void, sender);
    if (![self isKindOfClass:[NSPanel class]] && ![self isKindOfClass:[NSMenu class]]) {
        [(NSWindow *)self setTitle:@"Your New Title"];
    }
}

- (void)setTitle:(NSString *)title {
    ZKOrig(void, @"Your New Title");
}

@end