#import <AppKit/AppKit.h>
#import "ZKSwizzle.h"

@interface CornerRadiusController : NSObject
@end

@implementation CornerRadiusController

+ (void)load {
    // Nothing needed here since we just want the swizzle
}

@end

// Swizzle the window for square corners
ZKSwizzleInterface(AS_NSWindow_CornerRadius, NSWindow, NSWindow)

@implementation AS_NSWindow_CornerRadius

- (id)_cornerMask {
    // Only modify windows that are titled (application windows)
    if (!(self.styleMask & NSWindowStyleMaskTitled)) {
        return ZKOrig(id);
    }
    
    // Create a 1x1 white image for square corners
    NSImage *squareCornerMask = [[NSImage alloc] initWithSize:NSMakeSize(1, 1)];
    [squareCornerMask lockFocus];
    [[NSColor whiteColor] set];
    NSRectFill(NSMakeRect(0, 0, 1, 1));
    [squareCornerMask unlockFocus];
    return squareCornerMask;
}

@end

// Swizzle the titlebar decoration view to prevent rounded corners
ZKSwizzleInterface(AS_TitlebarDecorationView, _NSTitlebarDecorationView, NSView)

@implementation AS_TitlebarDecorationView

- (void)viewDidMoveToWindow {
    ZKOrig(void);
    // Only hide decoration for windows that are titled (application windows)
    if (self.window.styleMask & NSWindowStyleMaskTitled) {
        self.hidden = YES;  // Hide the decoration view entirely
    }
}

- (void)drawRect:(NSRect)dirtyRect {
    // Only prevent drawing for titled windows
    if (self.window.styleMask & NSWindowStyleMaskTitled) {
        return;  // No-op to prevent any drawing
    }
    ZKOrig(void);
}

@end