#import <AppKit/AppKit.h>

@interface macwmfxStyler : NSObject

/**
 * Applies the appearance configuration to a specific window.
 */
+ (void)applyStyleToWindow:(NSWindow *)window;

/**
 * Convenience method to refresh all windows.
 */
+ (void)refreshAllWindows;

@end
