#import "macwmfx_globals.h"

ZKSwizzleInterface(BS_NSWindow_Traffic, NSWindow, NSWindow)

@implementation BS_NSWindow_Traffic

- (nullable NSButton *)standardWindowButton:(NSWindowButton)b {
    NSButton *button = ZKOrig(NSButton*, b);
    if (button) {
        // Move traffic lights to the right side
        NSView *titleBar = [button superview];
        if (titleBar) {
            [titleBar addSubview:button];
            
            // Adjust the ordering: zoom, minimize, close
            if (b == NSWindowCloseButton) {
                // Move close button to the rightmost position
                [button setFrameOrigin:NSMakePoint(titleBar.frame.size.width - button.frame.size.width - 10, button.frame.origin.y)];
            } else if (b == NSWindowZoomButton) {
                // Move zoom button to the left of close button
                NSButton *closeButton = ZKOrig(NSButton*, NSWindowCloseButton);
                if (closeButton) {
                    CGFloat zoomX = closeButton.frame.origin.x - button.frame.size.width - 10;
                    [button setFrameOrigin:NSMakePoint(zoomX, button.frame.origin.y)];
                }
            } else if (b == NSWindowMiniaturizeButton) {
                // Move minimize button to the left of zoom button
                NSButton *zoomButton = ZKOrig(NSButton*, NSWindowZoomButton);
                if (zoomButton) {
                    CGFloat minimizeX = zoomButton.frame.origin.x - button.frame.size.width - 10;
                    [button setFrameOrigin:NSMakePoint(minimizeX, button.frame.origin.y)];
                }
            }
        }
        return button;
    }
    return button;
}

@end