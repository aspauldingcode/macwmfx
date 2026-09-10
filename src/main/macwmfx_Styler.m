/**
 * macwmfx_Styler.m - Window Styling Engine
 *
 * Redesigned implementation using proven techniques from reference projects:
 * - Corner radius via private KVC (apple-sharpener)
 * - Borders/shadows via child BorderFrameWindow (apple-sharpener)
 * - Materials via NSVisualEffectView manipulation (AeroFinder)
 *
 * @author Alex "aspauldingcode"
 * @version 2.0
 */

#import "macwmfx_Styler.h"
#import "../modules/windows/features/effects/WindowDragEffects.h"
#import "../modules/windows/features/frame/BorderFrameWindow.h"
#import "../shared/headers/macwmfx_Common.h"
#import "../shared/headers/window_filter.h"
#import "../shared/macwmfx_logging.h"
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

#pragma mark - Color Parsing Helper

static NSColor *colorFromHexString(NSString *hexString) {
  if (!hexString || hexString.length < 7)
    return nil;

  unsigned int r = 0, g = 0, b = 0, a = 255;
  NSString *hex =
      [hexString hasPrefix:@"#"] ? [hexString substringFromIndex:1] : hexString;

  if (hex.length >= 6) {
    [[NSScanner scannerWithString:[hex substringWithRange:NSMakeRange(0, 2)]]
        scanHexInt:&r];
    [[NSScanner scannerWithString:[hex substringWithRange:NSMakeRange(2, 2)]]
        scanHexInt:&g];
    [[NSScanner scannerWithString:[hex substringWithRange:NSMakeRange(4, 2)]]
        scanHexInt:&b];
  }
  if (hex.length >= 8) {
    [[NSScanner scannerWithString:[hex substringWithRange:NSMakeRange(6, 2)]]
        scanHexInt:&a];
  }

  return [NSColor colorWithRed:r / 255.0
                         green:g / 255.0
                          blue:b / 255.0
                         alpha:a / 255.0];
}

#pragma mark - Corner Radius via Private KVC

// Recursion guard
static const void *kApplyingStyleKey = &kApplyingStyleKey;

static BOOL isApplyingStyle(NSWindow *window) {
  return [objc_getAssociatedObject(window, kApplyingStyleKey) boolValue];
}

static void setApplyingStyle(NSWindow *window, BOOL applying) {
  objc_setAssociatedObject(window, kApplyingStyleKey, @(applying),
                           OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

/**
 * Minimum corner radius value - used when config specifies 0.0
 * Using a tiny epsilon tricks macOS into applying visually-zero radius
 */
static const CGFloat kMinimumCornerRadius = 1e-10;

/**
 * Apply corner radius using private KVC - THE KEY MECHANISM
 * For radius 0 (square corners), uses minimal epsilon value
 */
static void applyCornerRadiusViaKVC(NSWindow *window, CGFloat radius) {
  if (!window)
    return;
  if (isApplyingStyle(window))
    return;

  setApplyingStyle(window, YES);
  @try {
    // For radius 0.0, use minimal epsilon to get visually square corners
    CGFloat effectiveRadius = (radius == 0.0) ? kMinimumCornerRadius : radius;

    // This is the ONLY mechanism that actually changes the window shape
    [(id)window setValue:@(effectiveRadius) forKey:@"cornerRadius"];

    MACWMFX_LOG_DEBUG(macwmfx_log_styler,
                      "Applied corner radius %.1f via KVC to window %ld",
                      radius, (long)window.windowNumber);
  } @catch (NSException *exception) {
    // Some windows don't support this - fall back to layer-based
    MACWMFX_LOG_DEBUG(
        macwmfx_log_styler,
        "KVC corner radius failed, using layer fallback for window %ld",
        (long)window.windowNumber);
    CGFloat effectiveRadius = (radius == 0.0) ? kMinimumCornerRadius : radius;
    NSView *themeFrame = [window.contentView superview];
    if (themeFrame) {
      themeFrame.wantsLayer = YES;
      themeFrame.layer.cornerRadius = effectiveRadius;
      themeFrame.layer.masksToBounds = (effectiveRadius > 0);
    }
  } @finally {
    setApplyingStyle(window, NO);
  }
}

@implementation macwmfxStyler

+ (void)applyStyleToWindow:(NSWindow *)window {
  if (!window)
    return;

  // Filter out system windows
  if (!macwmfx_isStandardAppWindow(window)) {
    MACWMFX_LOG_DEBUG(macwmfx_log_styler, "Skipping non-standard window: %ld",
                      (long)window.windowNumber);
    return;
  }

  @try {
    NSDictionary *config =
        [macwmfxRuleEngine resolveAppearanceForWindow:window];
    if (!config || config.count == 0) {
      MACWMFX_LOG_DEBUG(macwmfx_log_styler,
                        "No config resolved for window: %ld",
                        (long)window.windowNumber);
      return;
    }

    MACWMFX_LOG_INFO(macwmfx_log_styler, "Applying style to window: %ld",
                     (long)window.windowNumber);

    [CATransaction begin];
    [CATransaction setDisableActions:YES];

    [self applyGeometry:config[@"geometry"] toWindow:window];
    [self applyMaterials:config[@"materials"] toWindow:window];
    [self applyDecoration:config[@"decoration"] toWindow:window];
    [self applyChrome:config[@"chrome"] toWindow:window];
    [self applyMotion:config[@"motion"] toWindow:window];

    [CATransaction commit];
  } @catch (NSException *exception) {
    MACWMFX_LOG_ERROR(macwmfx_log_styler, "Exception styling window %ld: %@",
                      (long)window.windowNumber, exception);
  }
}

#pragma mark - Geometry

+ (void)applyGeometry:(NSDictionary *)geometry toWindow:(NSWindow *)window {
  if (!geometry)
    return;

  // Corner Radius - Use private KVC for actual window shape change
  id cornerRadius = geometry[@"cornerRadius"];
  if (cornerRadius) {
    CGFloat radius = [cornerRadius doubleValue];
    applyCornerRadiusViaKVC(window, radius);

    // Also update the frame window if it exists
    FrameWindowManager *manager = [FrameWindowManager sharedManager];
    BorderFrameWindow *frame = [manager frameForWindow:window];
    if (frame) {
      frame.cornerRadius = radius;
      [frame updateFrameToMatchTarget];
    }
  }

  // Asymmetric Radius - Future implementation
  if (geometry[@"asymmetricRadius"]) {
    MACWMFX_LOG_DEBUG(macwmfx_log_styler,
                      "Asymmetric radius not yet implemented for window %ld",
                      (long)window.windowNumber);
  }

  // Content Padding - Future implementation
  if (geometry[@"contentPadding"]) {
    // Could be implemented by adjusting contentView insets
  }
}

#pragma mark - Materials

+ (void)applyMaterials:(NSDictionary *)materials toWindow:(NSWindow *)window {
  if (!materials)
    return;

  // Vibrancy via NSVisualEffectView or NSAppearance
  NSString *vibrancy = materials[@"vibrancy"];
  if (vibrancy && ![vibrancy isEqualToString:@"none"]) {
    NSVisualEffectMaterial material = NSVisualEffectMaterialPopover;

    if ([vibrancy isEqualToString:@"sidebar"])
      material = NSVisualEffectMaterialSidebar;
    else if ([vibrancy isEqualToString:@"menu"])
      material = NSVisualEffectMaterialMenu;
    else if ([vibrancy isEqualToString:@"popover"])
      material = NSVisualEffectMaterialPopover;
    else if ([vibrancy isEqualToString:@"hud"])
      material = NSVisualEffectMaterialHUDWindow;
    else if ([vibrancy isEqualToString:@"light"])
      material = NSVisualEffectMaterialLight;
    else if ([vibrancy isEqualToString:@"dark"])
      material = NSVisualEffectMaterialDark;
    else if ([vibrancy isEqualToString:@"ultra-thin"])
      material = NSVisualEffectMaterialUnderWindowBackground;

    NSView *contentView = window.contentView;
    if ([contentView isKindOfClass:[NSVisualEffectView class]]) {
      ((NSVisualEffectView *)contentView).material = material;
      ((NSVisualEffectView *)contentView).state =
          NSVisualEffectStateFollowsWindowActiveState;
    } else {
      // Set appearance as fallback
      if ([vibrancy isEqualToString:@"dark"]) {
        window.appearance =
            [NSAppearance appearanceNamed:NSAppearanceNameVibrantDark];
      } else if ([vibrancy isEqualToString:@"light"]) {
        window.appearance =
            [NSAppearance appearanceNamed:NSAppearanceNameVibrantLight];
      }
    }
  }

  // Opacity
  if (materials[@"opacity"]) {
    window.alphaValue = [materials[@"opacity"] doubleValue];
  }

  // Tint color
  NSString *tint = materials[@"tint"];
  if (tint) {
    NSColor *tintColor = colorFromHexString(tint);
    if (tintColor && tintColor.alphaComponent > 0) {
      window.backgroundColor = tintColor;
    }
  }
}

#pragma mark - Decoration (Borders/Shadows via Frame Window)

+ (void)applyDecoration:(NSDictionary *)decoration toWindow:(NSWindow *)window {
  if (!decoration)
    return;

  FrameWindowManager *manager = [FrameWindowManager sharedManager];
  NSDictionary *border = decoration[@"border"];
  NSDictionary *shadow = decoration[@"shadow"];
  NSDictionary *glow = border[@"glow"];

  BOOL needsFrame = NO;

  // Check if we need a frame window
  if (border && [border[@"enabled"] boolValue]) {
    needsFrame = YES;
  }
  if (shadow && [shadow[@"enabled"] boolValue] && shadow[@"stacks"]) {
    // Custom shadow stacks require frame window
    needsFrame = YES;
  }
  if (glow && [glow[@"radius"] doubleValue] > 0) {
    needsFrame = YES;
  }

  if (needsFrame) {
    // Configure global manager settings
    if (border) {
      manager.borderEnabled = [border[@"enabled"] boolValue];
      if (border[@"thickness"]) {
        manager.borderThickness = [border[@"thickness"] doubleValue];
      }

      // Parse gradient for active color
      NSArray *gradient = border[@"gradient"];
      if (gradient.count >= 2) {
        NSDictionary *first = gradient[0];
        manager.borderColorActive =
            colorFromHexString(first[@"color"]) ?: manager.borderColorActive;
        manager.borderColorInactive =
            [manager.borderColorActive colorWithAlphaComponent:0.5];
      }
    }

    if (glow) {
      manager.glowEnabled = ([glow[@"radius"] doubleValue] > 0);
      manager.glowRadius = [glow[@"radius"] doubleValue];
      manager.glowColorActive =
          colorFromHexString(glow[@"color"]) ?: manager.glowColorActive;
      manager.glowColorInactive = [NSColor clearColor];
    }

    // Get geometry corner radius if available
    NSDictionary *config =
        [macwmfxRuleEngine resolveAppearanceForWindow:window];
    NSDictionary *geometry = config[@"geometry"];
    if (geometry[@"cornerRadius"]) {
      manager.cornerRadius = [geometry[@"cornerRadius"] doubleValue];
    }

    // Create or update frame
    BorderFrameWindow *frame = [manager frameForWindow:window];
    if (!frame) {
      frame = [manager createFrameForWindow:window];
    } else {
      [manager updateFrameForWindow:window];
    }
  }

  // Standard shadow (when not using custom shadow stacks)
  if (shadow) {
    BOOL shadowEnabled = [shadow[@"enabled"] boolValue];
    // Disable system shadow if we're using frame window shadows
    if (needsFrame) {
      window.hasShadow = NO;
    } else {
      window.hasShadow = shadowEnabled;
    }
  }
}

#pragma mark - Chrome (Titlebar/Traffic Lights)

+ (void)applyChrome:(NSDictionary *)chrome toWindow:(NSWindow *)window {
  if (!chrome)
    return;

  NSDictionary *titlebar = chrome[@"titlebar"];
  if (titlebar) {
    NSString *style = titlebar[@"style"];

    if ([style isEqualToString:@"hidden"]) {
      window.titleVisibility = NSWindowTitleHidden;
      window.titlebarAppearsTransparent = YES;
      window.styleMask |= NSWindowStyleMaskFullSizeContentView;
    } else if ([style isEqualToString:@"unified"]) {
      window.titleVisibility = NSWindowTitleVisible;
      window.titlebarAppearsTransparent = YES;
      window.styleMask |= NSWindowStyleMaskFullSizeContentView;
    } else if ([style isEqualToString:@"split"]) {
      window.titleVisibility = NSWindowTitleVisible;
      window.titlebarAppearsTransparent = NO;
    }

    if (titlebar[@"transparent"] && [titlebar[@"transparent"] boolValue]) {
      window.titlebarAppearsTransparent = YES;
    }
  }

  NSDictionary *trafficLights = chrome[@"trafficLights"];
  if (trafficLights) {
    NSArray *position = trafficLights[@"position"];
    if (position.count >= 2) {
      CGFloat x = [position[0] doubleValue];
      CGFloat y = [position[1] doubleValue];

      NSButton *close = [window standardWindowButton:NSWindowCloseButton];
      NSButton *mini = [window standardWindowButton:NSWindowMiniaturizeButton];
      NSButton *zoom = [window standardWindowButton:NSWindowZoomButton];

      CGFloat spacing = [trafficLights[@"spacing"] doubleValue] ?: 8.0;

      if (close && close.superview) {
        NSRect closeFrame = close.frame;
        closeFrame.origin.x = x;
        closeFrame.origin.y =
            close.superview.frame.size.height - y - closeFrame.size.height;
        close.frame = closeFrame;
      }
      if (mini && mini.superview) {
        NSRect miniFrame = mini.frame;
        miniFrame.origin.x = x + spacing + miniFrame.size.width;
        miniFrame.origin.y =
            mini.superview.frame.size.height - y - miniFrame.size.height;
        mini.frame = miniFrame;
      }
      if (zoom && zoom.superview) {
        NSRect zoomFrame = zoom.frame;
        zoomFrame.origin.x = x + (spacing + zoomFrame.size.width) * 2;
        zoomFrame.origin.y =
            zoom.superview.frame.size.height - y - zoomFrame.size.height;
        zoom.frame = zoomFrame;
      }
    }

    // Scale (future implementation - requires transform)
    if (trafficLights[@"scale"]) {
      MACWMFX_LOG_DEBUG(
          macwmfx_log_styler,
          "Traffic light scale not yet implemented for window %ld",
          (long)window.windowNumber);
    }
  }
}

#pragma mark - Refresh All

+ (void)refreshAllWindows {
  dispatch_async(dispatch_get_main_queue(), ^{
    // Start the frame window manager if not already running
    [[FrameWindowManager sharedManager] startManaging];

    for (NSWindow *window in [NSApp windows]) {
      if (macwmfx_isStandardAppWindow(window)) {
        [self applyStyleToWindow:window];
      }
    }
  });
}

+ (void)applyMotion:(NSDictionary *)motion toWindow:(NSWindow *)window {
  if (!motion)
    return;

  NSDictionary *dragEffect = motion[@"dragEffect"];
  if (dragEffect) {
    WindowDragEffectManager *manager = [WindowDragEffectManager sharedManager];
    manager.config = [WindowDragEffectConfig configFromDictionary:dragEffect];
    manager.enabled = manager.config.enabled;

    MACWMFX_LOG_DEBUG(macwmfx_log_styler,
                      "Applied motion config (effect: %ld) via window %ld",
                      (long)manager.config.effect, (long)window.windowNumber);
  }
}

@end
