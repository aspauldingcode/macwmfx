/**
 * TitlebarDecorationViewSwizzle.m - Disable _NSTitlebarDecorationView
 *
 * Permanently disables the _NSTitlebarDecorationView and overrides
 * NSWindow's _cornerMask to ensure truly square window corners.
 *
 * This swizzle is ALWAYS active for titled application windows.
 *
 * @author Alex "aspauldingcode"
 * @version 1.1
 */

#import "../../../../shared/ZKSwizzle/ZKSwizzle.h"
#import "../../../../shared/headers/window_filter.h"
#import "../../../../shared/macwmfx_logging.h"
#import <AppKit/AppKit.h>

#pragma mark - Swizzled NSWindow _cornerMask

/**
 * Swizzle NSWindow to enforce square corners for application windows.
 * The _cornerMask method returns an image used as the corner mask.
 * By returning a 1x1 white pixel, we get perfectly square corners.
 */
ZKSwizzleInterface(MACWMFX_NSWindow_CornerMask, NSWindow, NSWindow)

    @implementation MACWMFX_NSWindow_CornerMask

- (id)_cornerMask {
  // Only modify windows that are titled (application windows)
  if (!(self.styleMask & NSWindowStyleMaskTitled)) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wcast-function-type-mismatch"
    return ZKOrig(id);
#pragma clang diagnostic pop
  }

  // Check if this is a standard app window we should modify
  if (!macwmfx_isStandardAppWindow((NSWindow *)self)) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wcast-function-type-mismatch"
    return ZKOrig(id);
#pragma clang diagnostic pop
  }

  // Create a 1x1 white image for square corners
  // This effectively removes any corner rounding
  NSImage *squareCornerMask = [[NSImage alloc] initWithSize:NSMakeSize(1, 1)];
  [squareCornerMask lockFocus];
  [[NSColor whiteColor] set];
  NSRectFill(NSMakeRect(0, 0, 1, 1));
  [squareCornerMask unlockFocus];

  MACWMFX_LOG_DEBUG(macwmfx_log_corners,
                    "Returned square corner mask for window %ld",
                    (long)[(NSWindow *)self windowNumber]);

  return squareCornerMask;
}

@end

#pragma mark - Swizzled _NSTitlebarDecorationView

/**
 * Swizzle _NSTitlebarDecorationView to prevent rounded corners.
 * This view is responsible for drawing the titlebar's corner decorations.
 * We hide it and prevent any drawing to ensure square corners.
 */
ZKSwizzleInterface(MACWMFX_TitlebarDecorationView, _NSTitlebarDecorationView,
                   NSView)

    @implementation MACWMFX_TitlebarDecorationView

- (void)viewDidMoveToWindow {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wcast-function-type-mismatch"
  ZKOrig(void);
#pragma clang diagnostic pop

  // Only hide decoration for windows that are titled (application windows)
  if (self.window && (self.window.styleMask & NSWindowStyleMaskTitled)) {
    if (macwmfx_isStandardAppWindow(self.window)) {
      self.hidden = YES; // Hide the decoration view entirely

      MACWMFX_LOG_DEBUG(macwmfx_log_corners,
                        "Hidden _NSTitlebarDecorationView for window %ld",
                        (long)self.window.windowNumber);
    }
  }
}

- (void)drawRect:(NSRect)dirtyRect {
  // Only prevent drawing for titled windows that we manage
  if (self.window && (self.window.styleMask & NSWindowStyleMaskTitled)) {
    if (macwmfx_isStandardAppWindow(self.window)) {
      return; // No-op to prevent any drawing
    }
  }

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wcast-function-type-mismatch"
  ZKOrig(void, dirtyRect);
#pragma clang diagnostic pop
}

@end

#pragma mark - Initialization

static void initializeTitlebarDecorationSwizzle(void)
    __attribute__((constructor));
static void initializeTitlebarDecorationSwizzle(void) {
  @try {
    if (!NSClassFromString(@"NSApplication"))
      return;
    if (!NSClassFromString(@"NSView"))
      return;

    MACWMFX_LOG_INFO(macwmfx_log_corners,
                     "Square corners swizzle initialized (_cornerMask + "
                     "_NSTitlebarDecorationView)");
  } @catch (NSException *e) {
    // Silently fail
  }
}
