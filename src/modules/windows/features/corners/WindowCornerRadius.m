/**
 * WindowCornerRadius.m - Window Corner Radius Control
 *
 * Implements the proven technique from apple-sharpener:
 * Uses private KVC `setValue:forKey:@"cornerRadius"` directly on NSWindow
 * to actually change the window shape (not just layer properties).
 *
 * Swizzles:
 * - initWithContentRect:styleMask:backing:defer:
 * - setFrame:display:
 * - _updateCornerMask
 * - _setCornerRadius:
 *
 * @author Alex "aspauldingcode"
 * @version 1.0
 */

#import "../../../../shared/ZKSwizzle/ZKSwizzle.h"
#import "../../../../shared/headers/window_filter.h"
#import "../../../../shared/macwmfx_logging.h"
#import <AppKit/AppKit.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

#pragma mark - Global State

static BOOL gCornerRadiusEnabled = YES;
static CGFloat gCornerRadiusValue = 10.0;
static BOOL gCornerRadiusInitialized = NO;

// Recursion guard to prevent infinite loops
static const void *kApplyingCornerRadiusKey = &kApplyingCornerRadiusKey;

static BOOL isApplyingCornerRadius(NSWindow *window) {
  return [objc_getAssociatedObject(window, kApplyingCornerRadiusKey) boolValue];
}

static void setApplyingCornerRadius(NSWindow *window, BOOL applying) {
  objc_setAssociatedObject(window, kApplyingCornerRadiusKey, @(applying),
                           OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - Corner Radius Constants

/**
 * Minimum corner radius value - used when config specifies 0.0
 * We use the smallest possible positive double because macOS's private
 * cornerRadius API treats true 0.0 specially and may still apply some rounding.
 * Using a tiny epsilon tricks the system into applying a visually-zero radius.
 */
static const CGFloat kMinimumCornerRadius = 1e-10;

#pragma mark - Core Corner Radius Application

/**
 * THE KEY MECHANISM - Sets window's private cornerRadius property via KVC
 * This is the ONLY way to actually change the window shape
 *
 * For radius 0 (square corners), we also manipulate the root CALayer
 * to completely remove macOS's default rounded corners
 */
static void applyCornerRadius(NSWindow *window) {
  if (!window || !gCornerRadiusEnabled)
    return;

  // Don't apply to non-standard windows
  if (!macwmfx_isStandardAppWindow(window))
    return;

  // Check recursion guard
  if (isApplyingCornerRadius(window))
    return;

  setApplyingCornerRadius(window, YES);
  @try {
    // CRITICAL: Set the window's private cornerRadius property via KVC
    // This is the mechanism that actually changes the window shape
    // For config value 0.0, we use a minimal epsilon to get visually square
    // corners
    CGFloat effectiveRadius =
        (gCornerRadiusValue == 0.0) ? kMinimumCornerRadius : gCornerRadiusValue;
    [(id)window setValue:@(effectiveRadius) forKey:@"cornerRadius"];

    MACWMFX_LOG_DEBUG(macwmfx_log_corners,
                      "Applied corner radius %.1f to window %ld",
                      gCornerRadiusValue, (long)window.windowNumber);
  } @catch (NSException *exception) {
    // Fail silently - some windows (Electron) may not support this property
    MACWMFX_LOG_DEBUG(macwmfx_log_corners,
                      "Could not apply corner radius to window %ld: %@",
                      (long)window.windowNumber, exception.reason);
  } @finally {
    setApplyingCornerRadius(window, NO);
  }
}

#pragma mark - Public API

void macwmfx_setCornerRadius(CGFloat radius) {
  gCornerRadiusValue = radius;
  gCornerRadiusEnabled = YES;

  // Update all existing windows
  dispatch_async(dispatch_get_main_queue(), ^{
    for (NSWindow *window in [NSApp windows]) {
      if (macwmfx_isStandardAppWindow(window)) {
        applyCornerRadius(window);
      }
    }
  });
}

void macwmfx_setCornerRadiusEnabled(BOOL enabled) {
  gCornerRadiusEnabled = enabled;

  if (!enabled) {
    // Reset to system default (approximately 10 on modern macOS)
    gCornerRadiusValue = 10.0;
  }

  // Update all existing windows
  dispatch_async(dispatch_get_main_queue(), ^{
    for (NSWindow *window in [NSApp windows]) {
      if (macwmfx_isStandardAppWindow(window)) {
        applyCornerRadius(window);
      }
    }
  });
}

#pragma mark - Swizzled NSWindow

ZKSwizzleInterface(MACWMFX_NSWindow_CornerRadius, NSWindow, NSWindow)

    @implementation MACWMFX_NSWindow_CornerRadius

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-designated-initializers"
- (id)initWithContentRect:(NSRect)contentRect
                styleMask:(NSWindowStyleMask)style
                  backing:(NSBackingStoreType)backingStoreType
                    defer:(BOOL)flag {
  id result = nil;
  BOOL swizzlingReady = YES;

  @try {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wcast-function-type-mismatch"
    result = ZKOrig(id, contentRect, style, backingStoreType, flag);
#pragma clang diagnostic pop
  } @catch (NSException *e) {
    // Swizzling not ready - call original directly
    swizzlingReady = NO;
    Method originalMethod =
        class_getInstanceMethod([NSWindow class], @selector
                                (initWithContentRect:styleMask:backing:defer:));
    if (originalMethod) {
      typedef id (*initIMP)(id, SEL, NSRect, NSWindowStyleMask,
                            NSBackingStoreType, BOOL);
      initIMP originalIMP = (initIMP)method_getImplementation(originalMethod);
      result = originalIMP(self,
                           @selector(initWithContentRect:
                                               styleMask:backing:defer:),
                           contentRect, style, backingStoreType, flag);
    } else {
      result = nil;
    }
  }

  // Apply corner radius if swizzling ready and window is standard
  if (swizzlingReady && gCornerRadiusEnabled && result) {
    NSWindow *window = (NSWindow *)result;
    if (macwmfx_isStandardAppWindow(window)) {
      dispatch_async(dispatch_get_main_queue(), ^{
        applyCornerRadius(window);
      });
    }
  }

  return result;
}
#pragma clang diagnostic pop

- (void)setFrame:(NSRect)frameRect display:(BOOL)flag {
  BOOL swizzlingReady = YES;

  @try {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wcast-function-type-mismatch"
    ZKOrig(void, frameRect, flag);
#pragma clang diagnostic pop
  } @catch (NSException *e) {
    swizzlingReady = NO;
    Method originalMethod =
        class_getInstanceMethod([NSWindow class], @selector(setFrame:display:));
    if (originalMethod) {
      typedef void (*setFrameIMP)(id, SEL, NSRect, BOOL);
      setFrameIMP originalIMP =
          (setFrameIMP)method_getImplementation(originalMethod);
      originalIMP(self, @selector(setFrame:display:), frameRect, flag);
    }
  }

  // Reapply corner radius after frame change
  if (swizzlingReady && gCornerRadiusEnabled &&
      macwmfx_isStandardAppWindow(self)) {
    applyCornerRadius(self);
  }
}

- (void)_updateCornerMask {
  if (gCornerRadiusEnabled && macwmfx_isStandardAppWindow(self)) {
    applyCornerRadius(self);
  } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wcast-function-type-mismatch"
    ZKOrig(void);
#pragma clang diagnostic pop
  }
}

- (void)_setCornerRadius:(CGFloat)radius {
  if (!gCornerRadiusEnabled) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wcast-function-type-mismatch"
    ZKOrig(void, radius);
#pragma clang diagnostic pop
    return;
  }

  // Don't apply custom radius to non-standard windows
  if (!macwmfx_isStandardAppWindow(self)) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wcast-function-type-mismatch"
    ZKOrig(void, radius);
#pragma clang diagnostic pop
    return;
  }

  // Check recursion guard
  if (isApplyingCornerRadius(self)) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wcast-function-type-mismatch"
    ZKOrig(void, gCornerRadiusValue);
#pragma clang diagnostic pop
    return;
  }

  // Force our custom corner radius
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wcast-function-type-mismatch"
  ZKOrig(void, gCornerRadiusValue);
#pragma clang diagnostic pop

  // Reapply to ensure window's cornerRadius property is set via KVC
  applyCornerRadius(self);
}

@end

#pragma mark - Swizzled NSPanel

ZKSwizzleInterface(MACWMFX_NSPanel_CornerRadius, NSPanel, NSWindow)

    @implementation MACWMFX_NSPanel_CornerRadius

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-designated-initializers"
- (id)initWithContentRect:(NSRect)contentRect
                styleMask:(NSWindowStyleMask)style
                  backing:(NSBackingStoreType)backingStoreType
                    defer:(BOOL)flag {
  id result = nil;
  BOOL swizzlingReady = YES;

  @try {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wcast-function-type-mismatch"
    result = ZKOrig(id, contentRect, style, backingStoreType, flag);
#pragma clang diagnostic pop
  } @catch (NSException *e) {
    swizzlingReady = NO;
    Method originalMethod =
        class_getInstanceMethod([NSWindow class], @selector
                                (initWithContentRect:styleMask:backing:defer:));
    if (originalMethod) {
      typedef id (*initIMP)(id, SEL, NSRect, NSWindowStyleMask,
                            NSBackingStoreType, BOOL);
      initIMP originalIMP = (initIMP)method_getImplementation(originalMethod);
      result = originalIMP(self,
                           @selector(initWithContentRect:
                                               styleMask:backing:defer:),
                           contentRect, style, backingStoreType, flag);
    } else {
      result = nil;
    }
  }

  if (swizzlingReady && gCornerRadiusEnabled && result) {
    NSWindow *window = (NSWindow *)result;
    if (macwmfx_isStandardAppWindow(window)) {
      dispatch_async(dispatch_get_main_queue(), ^{
        applyCornerRadius(window);
      });
    }
  }

  return result;
}
#pragma clang diagnostic pop

- (void)setFrame:(NSRect)frameRect display:(BOOL)flag {
  BOOL swizzlingReady = YES;

  @try {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wcast-function-type-mismatch"
    ZKOrig(void, frameRect, flag);
#pragma clang diagnostic pop
  } @catch (NSException *e) {
    swizzlingReady = NO;
    Method originalMethod =
        class_getInstanceMethod([NSWindow class], @selector(setFrame:display:));
    if (originalMethod) {
      typedef void (*setFrameIMP)(id, SEL, NSRect, BOOL);
      setFrameIMP originalIMP =
          (setFrameIMP)method_getImplementation(originalMethod);
      originalIMP(self, @selector(setFrame:display:), frameRect, flag);
    }
  }

  if (swizzlingReady && gCornerRadiusEnabled &&
      macwmfx_isStandardAppWindow(self)) {
    applyCornerRadius(self);
  }
}

- (void)_updateCornerMask {
  if (gCornerRadiusEnabled && macwmfx_isStandardAppWindow(self)) {
    applyCornerRadius(self);
  } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wcast-function-type-mismatch"
    ZKOrig(void);
#pragma clang diagnostic pop
  }
}

@end

// NOTE: _NSTitlebarDecorationView swizzle is now in
// TitlebarDecorationViewSwizzle.m

#pragma mark - Initialization

static void setupCornerRadiusNotifications(void) __attribute__((constructor));
static void setupCornerRadiusNotifications(void) {
  @try {
    if (!NSClassFromString(@"NSApplication"))
      return;
    if (!NSClassFromString(@"NSWindow"))
      return;

    // Initialize swizzle group
    ZKSwizzleGroup(MACWMFX_CORNER_RADIUS);

    gCornerRadiusInitialized = YES;
    MACWMFX_LOG_INFO(macwmfx_log_corners, "Corner radius module initialized");

    // Delay to ensure app is fully launched
    dispatch_after(
        dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)),
        dispatch_get_main_queue(), ^{
          // Apply to existing windows
          for (NSWindow *window in [NSApp windows]) {
            if (macwmfx_isStandardAppWindow(window)) {
              applyCornerRadius(window);
            }
          }
        });
  } @catch (NSException *e) {
    // Silently fail
  }
}
