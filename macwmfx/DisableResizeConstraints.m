#import "macwmfx_globals.h"

ZKSwizzleInterface(BS_NSWindow_Resize, NSWindow, NSWindow)

@implementation BS_NSWindow_Resize

- (void)makeKeyAndOrderFront:(id)sender {
    ZKOrig(void, sender);
    
    // Skip if this is not a regular window (e.g., menu, tooltip, etc.)
    if (!(self.styleMask & NSWindowStyleMaskTitled)) return;
    
    // Skip if window is a panel, sheet, or other special window type
    if (self.styleMask & (NSWindowStyleMaskHUDWindow | 
                         NSWindowStyleMaskNonactivatingPanel | 
                         NSWindowStyleMaskUtilityWindow)) return;
    
    // Skip if window doesn't want to be resizable (check original style mask)
    if (!(self.styleMask & NSWindowStyleMaskResizable)) return;
    
    // Skip if window has a fixed aspect ratio
    if ([self respondsToSelector:@selector(aspectRatio)] && !NSEqualSizes([self aspectRatio], NSZeroSize)) return;
    
    // Skip if window has content size constraints
    NSSize minContentSize = [self contentMinSize];
    NSSize maxContentSize = [self contentMaxSize];
    if (!NSEqualSizes(minContentSize, NSZeroSize) && !NSEqualSizes(maxContentSize, NSZeroSize) &&
        NSEqualSizes(minContentSize, maxContentSize)) return;
    
    // Disable resize constraints if the setting is enabled
    if (gDisableWindowSizeConstraints) {
        [self disableResizeConstraints];
    }
}

- (void)disableResizeConstraints {
    // Skip if this is not a regular window (e.g., menu, tooltip, etc.)
    if (!(self.styleMask & NSWindowStyleMaskTitled)) return;
    
    // Skip if window is a panel, sheet, or other special window type
    if (self.styleMask & (NSWindowStyleMaskHUDWindow | 
                         NSWindowStyleMaskNonactivatingPanel | 
                         NSWindowStyleMaskUtilityWindow)) return;
    
    // Skip if window doesn't want to be resizable (check original style mask)
    if (!(self.styleMask & NSWindowStyleMaskResizable)) return;
    
    // Skip if window has a fixed aspect ratio
    if ([self respondsToSelector:@selector(aspectRatio)] && !NSEqualSizes([self aspectRatio], NSZeroSize)) return;
    
    // Skip if window has content size constraints
    NSSize minContentSize = [self contentMinSize];
    NSSize maxContentSize = [self contentMaxSize];
    if (!NSEqualSizes(minContentSize, NSZeroSize) && !NSEqualSizes(maxContentSize, NSZeroSize) &&
        NSEqualSizes(minContentSize, maxContentSize)) return;
    
    // Directly use self as NSWindow instead of accessing a private ivar
    NSWindow *window = (NSWindow *)self;
    
    // Ensure window exists and can be resized
    if (!window || ![window respondsToSelector:@selector(setMinSize:)] || 
        ![window respondsToSelector:@selector(setMaxSize:)]) return;
    
    // Get current window size
    NSSize currentSize = window.frame.size;
    
    // Try to modify constraints within a @try block to catch any exceptions
    @try {
        // Enable resizing and remove constraints while preserving current size
        window.styleMask |= NSWindowStyleMaskResizable;
        [window setMinSize:NSMakeSize(currentSize.width * 0.5, currentSize.height * 0.5)];  // Allow 50% smaller
        [window setMaxSize:NSMakeSize(currentSize.width * 2.0, currentSize.height * 2.0)];  // Allow 200% larger
        
        // Ensure window stays at current size after removing constraints
        [window setFrame:NSMakeRect(window.frame.origin.x, 
                                   window.frame.origin.y, 
                                   currentSize.width, 
                                   currentSize.height) 
                 display:YES];
    } @catch (NSException *exception) {
        // If anything goes wrong, restore original state and skip this window
        window.styleMask &= ~NSWindowStyleMaskResizable;
        return;
    }
}

@end