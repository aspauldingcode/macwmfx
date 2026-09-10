/**
 * window_filter.h - Window Filtering Utilities for macwmfx
 *
 * Comprehensive window filtering logic to determine which windows should
 * receive macwmfx styling. Ported from apple-sharpener with enhancements.
 *
 * IMPORTANT: This is a GLOBAL tweak - applies to ALL applications.
 *
 * @author Alex "aspauldingcode"
 * @version 1.0
 */

#ifndef WINDOW_FILTER_H
#define WINDOW_FILTER_H

#import <AppKit/AppKit.h>
#import <math.h>

#pragma mark - Fullscreen Detection

/**
 * Check if a window is fullscreen (including titlebar-only fullscreen)
 */
static inline BOOL macwmfx_isWindowFullscreen(NSWindow *window) {
  if (!window)
    return NO;
  @try {
    // Check style mask first
    if ((window.styleMask & NSWindowStyleMaskFullScreen) ==
        NSWindowStyleMaskFullScreen)
      return YES;

    // Check via isFullScreen method if available (private API)
    if ([window respondsToSelector:@selector(isFullScreen)]) {
      NSInvocation *invocation = [NSInvocation
          invocationWithMethodSignature:[window
                                            methodSignatureForSelector:@selector
                                            (isFullScreen)]];
      [invocation setSelector:@selector(isFullScreen)];
      [invocation setTarget:window];
      [invocation invoke];
      BOOL result = NO;
      [invocation getReturnValue:&result];
      if (result)
        return YES;
    }

    // Check for fullscreen titlebar (window fills screen but may have titlebar)
    NSScreen *screen = window.screen ?: [NSScreen mainScreen];
    if (screen) {
      NSRect screenFrame = screen.frame;
      NSRect windowFrame = window.frame;
      // Allow small tolerance for menu bar
      if (fabs(windowFrame.origin.x - screenFrame.origin.x) < 1 &&
          fabs(windowFrame.origin.y - screenFrame.origin.y) < 1 &&
          fabs(windowFrame.size.width - screenFrame.size.width) < 1 &&
          fabs(windowFrame.size.height - screenFrame.size.height) < 1) {
        return YES;
      }
    }
  } @catch (NSException *e) {
  }
  return NO;
}

#pragma mark - System Window Detection

/**
 * Check if a window is a Dock tile right-click menu
 */
static inline BOOL macwmfx_isDockTileMenuWindow(NSWindow *window) {
  if (!window)
    return NO;
  @try {
    NSString *className = NSStringFromClass([window class]);

    // Check for Dock-related window class names
    if ([className containsString:@"Dock"] ||
        [className containsString:@"DockTile"] ||
        [className containsString:@"DockMenu"]) {
      return YES;
    }

    // Dock tile menus are typically small borderless windows at high levels
    NSWindowLevel level = window.level;
    if (level >= NSPopUpMenuWindowLevel) {
      NSRect frame = window.frame;
      if ((window.styleMask & NSWindowStyleMaskTitled) == 0 &&
          (window.styleMask & NSWindowStyleMaskBorderless) != 0 &&
          frame.size.width < 500 && frame.size.height < 500) {
        // Check if near bottom of screen (dock area)
        NSScreen *screen = window.screen ?: [NSScreen mainScreen];
        if (screen) {
          NSRect screenFrame = screen.frame;
          CGFloat distanceFromBottom = frame.origin.y - screenFrame.origin.y;
          if (distanceFromBottom < screenFrame.size.height * 0.3) {
            return YES;
          }
        }
        return YES;
      }
    }
  } @catch (NSException *e) {
  }
  return NO;
}

/**
 * Check if a window is Exposé or Mission Control overlay
 */
static inline BOOL macwmfx_isExposeOrMissionControlWindow(NSWindow *window) {
  if (!window)
    return NO;
  @try {
    NSString *className = NSStringFromClass([window class]);

    if ([className containsString:@"Expose"] ||
        [className containsString:@"Exposé"] ||
        [className containsString:@"MissionControl"] ||
        [className containsString:@"Mission Control"] ||
        [className containsString:@"Desktop"] ||
        [className containsString:@"Spaces"] ||
        [className containsString:@"Space"] ||
        [className containsString:@"Workspace"] ||
        [className containsString:@"Switcher"]) {
      return YES;
    }

    NSWindowLevel level = window.level;
    if (level >= NSMainMenuWindowLevel) {
      NSRect windowFrame = window.frame;
      NSScreen *screen = window.screen ?: [NSScreen mainScreen];
      if (screen) {
        NSRect screenFrame = screen.frame;
        CGFloat screenArea = screenFrame.size.width * screenFrame.size.height;
        CGFloat windowArea = windowFrame.size.width * windowFrame.size.height;
        // Large overlay or small high-level window
        if (windowArea > screenArea * 0.8 ||
            (windowArea < screenArea * 0.1 && level >= NSMainMenuWindowLevel)) {
          return YES;
        }
      }
    }
  } @catch (NSException *e) {
  }
  return NO;
}

/**
 * Check if a window is a Spotlight window
 */
static inline BOOL macwmfx_isSpotlightWindow(NSWindow *window) {
  if (!window)
    return NO;
  @try {
    NSString *className = NSStringFromClass([window class]);

    if ([className containsString:@"Spotlight"] ||
        [className containsString:@"SFL"] ||
        [className containsString:@"Siri"]) {
      return YES;
    }

    NSWindowLevel level = window.level;
    if (level >= NSMainMenuWindowLevel) {
      NSScreen *screen = window.screen ?: [NSScreen mainScreen];
      if (screen) {
        NSRect screenFrame = screen.frame;
        NSRect windowFrame = window.frame;
        CGFloat centerX = screenFrame.origin.x + screenFrame.size.width / 2;
        CGFloat windowCenterX =
            windowFrame.origin.x + windowFrame.size.width / 2;
        CGFloat distanceFromTop =
            (screenFrame.origin.y + screenFrame.size.height) -
            (windowFrame.origin.y + windowFrame.size.height);

        if (fabs(windowCenterX - centerX) < screenFrame.size.width * 0.3 &&
            distanceFromTop < screenFrame.size.height * 0.2 &&
            (window.styleMask & NSWindowStyleMaskBorderless) != 0) {
          return YES;
        }
      }
    }
  } @catch (NSException *e) {
  }
  return NO;
}

/**
 * Check if a window is a Control Center window
 */
static inline BOOL macwmfx_isControlCenterWindow(NSWindow *window) {
  if (!window)
    return NO;
  @try {
    NSString *className = NSStringFromClass([window class]);

    if ([className containsString:@"ControlCenter"] ||
        [className containsString:@"Control Center"] ||
        [className containsString:@"CC"]) {
      return YES;
    }

    NSWindowLevel level = window.level;
    if (level >= NSMainMenuWindowLevel) {
      NSScreen *screen = window.screen ?: [NSScreen mainScreen];
      if (screen) {
        NSRect screenFrame = screen.frame;
        NSRect windowFrame = window.frame;
        CGFloat distanceFromRight =
            (screenFrame.origin.x + screenFrame.size.width) -
            (windowFrame.origin.x + windowFrame.size.width);
        if (distanceFromRight < 50 &&
            (window.styleMask & NSWindowStyleMaskBorderless) != 0) {
          return YES;
        }
      }
    }
  } @catch (NSException *e) {
  }
  return NO;
}

/**
 * Check if a window is a menubar or menubar applet
 */
static inline BOOL macwmfx_isMenubarWindow(NSWindow *window) {
  if (!window)
    return NO;
  @try {
    NSString *className = NSStringFromClass([window class]);

    if ([className containsString:@"Menubar"] ||
        [className containsString:@"MenuBar"] ||
        [className containsString:@"NSStatusBar"] ||
        [className containsString:@"StatusBar"] ||
        [className containsString:@"Applet"] ||
        [className containsString:@"MenuExtra"]) {
      return YES;
    }

    NSWindowLevel level = window.level;
    if (level >= NSMainMenuWindowLevel) {
      NSScreen *screen = window.screen ?: [NSScreen mainScreen];
      if (screen) {
        NSRect screenFrame = screen.frame;
        NSRect windowFrame = window.frame;
        CGFloat distanceFromTop =
            (screenFrame.origin.y + screenFrame.size.height) -
            (windowFrame.origin.y + windowFrame.size.height);
        // Menubar is typically 22-25 pixels tall
        if (distanceFromTop < 50 && windowFrame.size.height < 50) {
          return YES;
        }
      }
    }
  } @catch (NSException *e) {
  }
  return NO;
}

/**
 * Check if a window is a context menu or popup menu
 */
static inline BOOL macwmfx_isContextMenuWindow(NSWindow *window) {
  if (!window)
    return NO;
  @try {
    NSString *className = NSStringFromClass([window class]);

    if ([className containsString:@"Menu"] ||
        [className containsString:@"Context"] ||
        [className containsString:@"Popup"] ||
        [className containsString:@"Tooltip"]) {
      return YES;
    }

    // Context menus typically have very high window levels
    NSWindowLevel level = window.level;
    if (level >= NSPopUpMenuWindowLevel) {
      return YES;
    }

    // Small untitled windows at high levels
    if ((window.styleMask & NSWindowStyleMaskTitled) == 0 &&
        window.frame.size.width < 200 && window.frame.size.height < 300) {
      if (level > NSStatusWindowLevel) {
        return YES;
      }
    }
  } @catch (NSException *e) {
  }
  return NO;
}

#pragma mark - Main Filter Function

/**
 * Check if a window should receive macwmfx styling.
 *
 * This is the main filter function. Returns YES for standard application
 * windows.
 *
 * Excludes:
 * - Sheets (modal dialogs attached to parent windows)
 * - Child windows (windows with a parent window)
 * - Fullscreen windows
 * - Context menus and popup menus
 * - Dock tile menus
 * - Exposé and Mission Control windows
 * - Spotlight windows
 * - Control Center windows
 * - Menubar applets and menubar itself
 * - Very high-level system windows
 *
 * @param window The window to check
 * @return YES if the window should receive styling, NO otherwise
 */
static inline BOOL macwmfx_isStandardAppWindow(NSWindow *window) {
  if (!window)
    return NO;

  @try {
    // Exclude sheets (modal dialogs attached to parent windows)
    if (window.sheetParent != nil)
      return NO;

    // Exclude child windows (subviews/internal windows)
    if ([window parentWindow] != nil)
      return NO;

    // Exclude fullscreen windows
    if (macwmfx_isWindowFullscreen(window))
      return NO;

    // Exclude context menus and popup menus
    if (macwmfx_isContextMenuWindow(window))
      return NO;

    // Exclude Dock tile menus
    if (macwmfx_isDockTileMenuWindow(window))
      return NO;

    // Exclude Exposé and Mission Control windows
    if (macwmfx_isExposeOrMissionControlWindow(window))
      return NO;

    // Exclude Spotlight windows
    if (macwmfx_isSpotlightWindow(window))
      return NO;

    // Exclude Control Center windows
    if (macwmfx_isControlCenterWindow(window))
      return NO;

    // Exclude menubar and menubar applets
    if (macwmfx_isMenubarWindow(window))
      return NO;

    NSWindowLevel level = window.level;

    // Exclude very high-level system windows (menubar and above)
    if (level > NSStatusWindowLevel)
      return NO;

    // All other windows are allowed
    return YES;
  } @catch (NSException *exception) {
    // Fail safe by excluding
    return NO;
  }
}

/**
 * Check if a window is a system UI window (minimal check)
 */
static inline BOOL macwmfx_isSystemUIWindow(NSWindow *window) {
  if (!window)
    return NO;

  @try {
    if (macwmfx_isWindowFullscreen(window))
      return YES;
    if (macwmfx_isContextMenuWindow(window))
      return YES;

    NSWindowLevel level = window.level;
    if (level > NSStatusWindowLevel)
      return YES;
    if ([window parentWindow] != nil)
      return YES;
  } @catch (NSException *e) {
  }

  return NO;
}

#endif /* WINDOW_FILTER_H */
