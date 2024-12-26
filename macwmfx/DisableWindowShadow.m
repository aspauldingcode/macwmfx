#import <Cocoa/Cocoa.h>
#import "ZKSwizzle.h"

@interface DisableWindowShadow : NSObject
@end

@implementation DisableWindowShadow

+ (void)load {
    // Nothing needed here since we just want the swizzle
}

@end

ZKSwizzleInterface(BS_NSWindow_Shadow, NSWindow, NSWindow)

@implementation BS_NSWindow_Shadow

- (void)makeKeyAndOrderFront:(id)sender {
    ZKOrig(void, sender);
    
    // Disable shadow for all windows
    NSWindow *window = (NSWindow *)self;
    [window setHasShadow:NO];
}

- (void)setHasShadow:(BOOL)hasShadow {
    // Always set shadow to NO
    ZKOrig(void, NO);
}

@end 