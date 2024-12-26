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
    
    // Enable resizing and remove constraints
    window.styleMask |= NSWindowStyleMaskResizable;
    [window setMinSize:NSMakeSize(0.0, 0.0)];
    [window setMaxSize:NSMakeSize(CGFLOAT_MAX, CGFLOAT_MAX)];
}

@end