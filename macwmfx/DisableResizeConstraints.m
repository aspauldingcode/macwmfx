#import <Cocoa/Cocoa.h>

@interface DisableResizeConstraints : NSObject

+ (void)load;

@end

@implementation DisableResizeConstraints

+ (void)load {
    NSArray *windows = [NSApp windows];
    
    for (NSWindow *window in windows) {
        // Remove minimum size constraints
        [window setMinSize:NSMakeSize(0, 0)];
        
        // Remove maximum size constraints
        [window setMaxSize:NSMakeSize(FLT_MAX, FLT_MAX)];
        
        // Allow the window to be resized freely
        [window setStyleMask:[window styleMask] | NSWindowStyleMaskResizable];
    }
}

@end 