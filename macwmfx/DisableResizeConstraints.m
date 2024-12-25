#import <AppKit/AppKit.h>
#import "ZKSwizzle.h"

@interface DisableResizeConstraints : NSObject
@end

@implementation DisableResizeConstraints

+ (void)load {
    // Nothing needed here since we just want the swizzle
}

@end

ZKSwizzleInterface(BS_NSWindow_Resize, NSWindow, NSWindow)

@implementation BS_NSWindow_Resize

- (void)makeKeyAndOrderFront:(id)sender {
    ZKOrig(void, sender);
    
    // Directly use self as NSWindow instead of accessing a private ivar
    NSWindow *window = (NSWindow *)self;
    
    // Ensure the window is resizable
    if (window.styleMask & NSWindowStyleMaskResizable) {
        [window setMinSize:NSMakeSize(100.0, 100.0)]; // Set a reasonable minimum size
        [window setMaxSize:NSMakeSize(10000.0, 10000.0)]; // Set a reasonable maximum size
    }
}

@end