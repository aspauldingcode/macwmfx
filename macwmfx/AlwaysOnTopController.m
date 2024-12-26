#import <AppKit/AppKit.h>
#import "ZKSwizzle.h"

@interface AlwaysOnTopController : NSObject
@end

@implementation AlwaysOnTopController

+ (void)load {
    // Nothing needed here since we just want the swizzle
}

@end

ZKSwizzleInterface(AX_NSWindow_AlwaysOnTop, NSWindow, NSWindow)

@implementation AX_NSWindow_AlwaysOnTop

- (void)makeKeyAndOrderFront:(id)sender {
    ZKOrig(void, sender);
    
    // Directly use self as NSWindow instead of accessing a private ivar
    NSWindow *window = (NSWindow *)self;
    
    // Check if window is floating in yabai by checking window properties
    // Floating windows typically have specific collection behaviors
    NSWindowCollectionBehavior behavior = [window collectionBehavior];
    BOOL isFloating = (behavior & NSWindowCollectionBehaviorCanJoinAllSpaces) ||
                     (behavior & NSWindowCollectionBehaviorTransient);
    
    // Set any floating window to always be on top
    if (isFloating) {
        [window setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces];
        [window setLevel:NSFloatingWindowLevel];
        [window setMovable:YES];
        [window setStyleMask:[window styleMask] | NSWindowStyleMaskResizable];
    }
}

@end