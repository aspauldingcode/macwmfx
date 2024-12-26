#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import "ZKSwizzle.h"

@interface NSWindow (Private)
- (id)_cornerMask;
@end

@interface CornerRadiusController : NSObject
@end

@implementation CornerRadiusController

+ (void)load {
    Method method = class_getInstanceMethod(NSClassFromString(@"NSWindow"), @selector(_cornerMask));
    IMP newIMP = imp_implementationWithBlock(^id(__unused id self) {
        // Create a 1x1 white image for square corners
        NSImage *squareCornerMask = [[NSImage alloc] initWithSize:NSMakeSize(1, 1)];
        [squareCornerMask lockFocus];
        [[NSColor whiteColor] set];
        NSRectFill(NSMakeRect(0, 0, 1, 1));
        [squareCornerMask unlockFocus];
        return squareCornerMask;
    });
    method_setImplementation(method, newIMP);
}

@end
