// #import <AppKit/AppKit.h>
// #import "ZKSwizzle.h"

// @interface AlwaysOnTopController : NSObject
// @end

// @implementation AlwaysOnTopController

// // + (void)load {
// //     // Nothing needed here since we just want the swizzle
// // }

// @end

// ZKSwizzleInterface(BS_NSWindow_AlwaysOnTop, NSWindow, NSWindow)

// @implementation BS_NSWindow_AlwaysOnTop

// - (void)makeKeyAndOrderFront:(id)sender {
//     ZKOrig(void, sender);
    
//     NSWindow *window = (NSWindow *)self;
//     window.level = NSFloatingWindowLevel;  // Set window to float above others
// }

// @end
