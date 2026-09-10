/**
 * BorderFrameWindow.m - Custom Border/Shadow Window Implementation
 *
 * Ported from apple-sharpener with enhancements for configurable borders,
 * shadows, and glow effects.
 *
 * @author Alex "aspauldingcode"
 * @version 1.0
 */

#import "BorderFrameWindow.h"
#import "../../../../shared/headers/window_filter.h"
#import "../../../../shared/macwmfx_logging.h"
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

#pragma mark - BorderFrameContentView

/**
 * Content view that draws the border/shadow/glow
 */
@interface BorderFrameContentView : NSView
@property(nonatomic, weak) BorderFrameWindow *frameWindow;
@end

@implementation BorderFrameContentView

- (BOOL)isFlipped {
  return NO;
}

- (void)drawRect:(NSRect)dirtyRect {
  BorderFrameWindow *frameWindow = self.frameWindow;
  if (!frameWindow)
    return;

  NSRect bounds = self.bounds;
  CGFloat borderThickness = frameWindow.borderThickness;
  CGFloat cornerRadius = frameWindow.cornerRadius;

  // Determine active color based on target window state
  BOOL isActive = frameWindow.targetWindow.isKeyWindow ||
                  frameWindow.targetWindow.isMainWindow;

  // Draw border if enabled
  if (borderThickness > 0) {
    NSColor *borderColor = isActive ? frameWindow.borderColorActive
                                    : frameWindow.borderColorInactive;
    if (borderColor) {
      [borderColor setFill];

      // Create outer path
      NSBezierPath *outerPath =
          [NSBezierPath bezierPathWithRoundedRect:bounds
                                          xRadius:cornerRadius
                                          yRadius:cornerRadius];

      // Create inner path (the "hole")
      NSRect innerRect = NSInsetRect(bounds, borderThickness, borderThickness);
      CGFloat innerRadius = MAX(0, cornerRadius - borderThickness);
      NSBezierPath *innerPath =
          [NSBezierPath bezierPathWithRoundedRect:innerRect
                                          xRadius:innerRadius
                                          yRadius:innerRadius];

      // Append inner path reversed to create a ring shape
      [outerPath appendBezierPath:innerPath.bezierPathByReversingPath];
      [outerPath fill];
    }
  }

  // Draw glow if enabled
  if (frameWindow.glowEnabled && frameWindow.glowRadius > 0) {
    NSColor *glowColor =
        isActive ? frameWindow.glowColorActive : frameWindow.glowColorInactive;
    if (glowColor) {
      // Create a glow effect using a shadow
      NSShadow *glow = [[NSShadow alloc] init];
      glow.shadowColor = glowColor;
      glow.shadowBlurRadius = frameWindow.glowRadius;
      glow.shadowOffset = NSZeroSize;

      [NSGraphicsContext saveGraphicsState];
      [glow set];

      // Draw a thin path to create the glow
      NSRect glowRect =
          NSInsetRect(bounds, borderThickness + 1, borderThickness + 1);
      CGFloat glowRadius = MAX(0, cornerRadius - borderThickness - 1);
      NSBezierPath *glowPath =
          [NSBezierPath bezierPathWithRoundedRect:glowRect
                                          xRadius:glowRadius
                                          yRadius:glowRadius];
      glowPath.lineWidth = 1.0;
      [[NSColor clearColor] setStroke];
      [glowColor setFill];
      [glowPath fill];

      [NSGraphicsContext restoreGraphicsState];
    }
  }
}

@end

#pragma mark - BorderFrameWindow

@implementation BorderFrameWindow

- (instancetype)initWithTargetWindow:(NSWindow *)targetWindow {
  NSRect frameRect = [self calculateFrameRectForTargetWindow:targetWindow];

  self = [super initWithContentRect:frameRect
                          styleMask:NSWindowStyleMaskBorderless
                            backing:NSBackingStoreBuffered
                              defer:NO];

  if (self) {
    _targetWindow = targetWindow;

    // Default configuration
    _borderThickness = 1.0;
    _borderColorActive = [NSColor colorWithWhite:1.0 alpha:0.3];
    _borderColorInactive = [NSColor colorWithWhite:1.0 alpha:0.15];
    _cornerRadius = 10.0;

    _shadowEnabled = YES;
    _shadowRadius = 20.0;
    _shadowColor = [NSColor colorWithWhite:0.0 alpha:0.5];
    _shadowOffset = NSMakePoint(0, -5);
    _shadowOpacity = 0.5;

    _glowEnabled = NO;
    _glowRadius = 4.0;
    _glowColorActive = [NSColor colorWithRed:0.0
                                       green:0.478
                                        blue:1.0
                                       alpha:0.4];
    _glowColorInactive = [NSColor clearColor];

    // Configure window
    self.backgroundColor = [NSColor clearColor];
    self.opaque = NO;
    self.hasShadow = _shadowEnabled;
    self.alphaValue = 1.0;
    self.level = targetWindow.level;
    self.ignoresMouseEvents = YES;
    self.collectionBehavior = NSWindowCollectionBehaviorIgnoresCycle |
                              NSWindowCollectionBehaviorStationary;

    // Create content view
    BorderFrameContentView *contentView = [[BorderFrameContentView alloc]
        initWithFrame:NSMakeRect(0, 0, frameRect.size.width,
                                 frameRect.size.height)];
    contentView.frameWindow = self;
    contentView.wantsLayer = YES;
    contentView.layer.backgroundColor = [[NSColor clearColor] CGColor];
    self.contentView = contentView;

    // Apply shadow if enabled
    if (_shadowEnabled) {
      NSShadow *shadow = [[NSShadow alloc] init];
      shadow.shadowColor = _shadowColor;
      shadow.shadowBlurRadius = _shadowRadius;
      shadow.shadowOffset = NSMakeSize(_shadowOffset.x, _shadowOffset.y);
      contentView.shadow = shadow;
    }

    MACWMFX_LOG_INFO(macwmfx_log_frame,
                     "Created BorderFrameWindow for window %ld",
                     (long)targetWindow.windowNumber);
  }

  return self;
}

- (NSRect)calculateFrameRectForTargetWindow:(NSWindow *)targetWindow {
  if (!targetWindow)
    return NSZeroRect;

  NSRect windowFrame = targetWindow.frame;
  CGFloat inset = _borderThickness + (_shadowEnabled ? _shadowRadius : 0);

  return NSMakeRect(windowFrame.origin.x - inset, windowFrame.origin.y - inset,
                    windowFrame.size.width + (inset * 2),
                    windowFrame.size.height + (inset * 2));
}

- (void)updateFrameToMatchTarget {
  if (!self.targetWindow)
    return;

  NSRect newFrame = [self calculateFrameRectForTargetWindow:self.targetWindow];
  [self setFrame:newFrame display:NO];
  self.level = self.targetWindow.level;

  // Force redraw
  [self.contentView setNeedsDisplay:YES];
}

- (void)updateColorForFocusState {
  // Force redraw with new focus state
  [self.contentView setNeedsDisplay:YES];
}

- (BOOL)shouldHideForFullscreen {
  if (!self.targetWindow)
    return NO;

  // Check style mask
  if ((self.targetWindow.styleMask & NSWindowStyleMaskFullScreen) ==
      NSWindowStyleMaskFullScreen) {
    return YES;
  }

  // Check if window frame matches screen frame
  @try {
    NSScreen *screen = self.targetWindow.screen ?: [NSScreen mainScreen];
    if (screen) {
      NSRect screenFrame = screen.frame;
      NSRect windowFrame = self.targetWindow.frame;
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

- (void)attachToTargetWindow {
  if (!self.targetWindow)
    return;

  // Don't attach if fullscreen
  if ([self shouldHideForFullscreen]) {
    if (self.isVisible) {
      [self orderOut:nil];
    }
    return;
  }

  // Attach as child window below parent
  if (!self.parentWindow) {
    [self.targetWindow addChildWindow:self ordered:NSWindowBelow];
  }

  // Sync level
  self.level = self.targetWindow.level;

  MACWMFX_LOG_DEBUG(macwmfx_log_frame,
                    "Attached BorderFrameWindow to window %ld",
                    (long)self.targetWindow.windowNumber);
}

- (void)detachFromTargetWindow {
  if (self.parentWindow == self.targetWindow) {
    [self.targetWindow removeChildWindow:self];
  }
  [self orderOut:nil];

  MACWMFX_LOG_DEBUG(macwmfx_log_frame, "Detached BorderFrameWindow");
}

- (BOOL)canBecomeKeyWindow {
  return NO;
}

- (BOOL)canBecomeMainWindow {
  return NO;
}

- (NSRect)constrainFrameRect:(NSRect)frameRect toScreen:(NSScreen *)screen {
  // Don't constrain - follow target window exactly
  return frameRect;
}

- (void)orderFront:(id)sender {
  if ([self shouldHideForFullscreen])
    return;
  [super orderFront:sender];
}

- (void)orderBack:(id)sender {
  if ([self shouldHideForFullscreen])
    return;
  [super orderBack:sender];
}

@end

#pragma mark - FrameWindowManager

@interface FrameWindowManager ()

@property(nonatomic, strong)
    NSMapTable<NSWindow *, BorderFrameWindow *> *windowToFrameMap;
@property(nonatomic, strong)
    NSHashTable<NSWindow *> *windowsInFullscreenTransition;
@property(nonatomic, assign) BOOL isManaging;

@end

@implementation FrameWindowManager

+ (instancetype)sharedManager {
  static FrameWindowManager *sharedManager = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedManager = [[FrameWindowManager alloc] init];
  });
  return sharedManager;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    _windowToFrameMap =
        [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsWeakMemory
                              valueOptions:NSPointerFunctionsStrongMemory];
    _windowsInFullscreenTransition =
        [NSHashTable hashTableWithOptions:NSPointerFunctionsWeakMemory];

    // Default configuration
    _borderEnabled = NO;
    _borderThickness = 1.0;
    _borderColorActive = [NSColor colorWithWhite:1.0 alpha:0.3];
    _borderColorInactive = [NSColor colorWithWhite:1.0 alpha:0.15];

    _shadowEnabled = YES;
    _shadowRadius = 20.0;
    _shadowColor = [NSColor colorWithWhite:0.0 alpha:0.5];

    _glowEnabled = NO;
    _glowRadius = 4.0;
    _glowColorActive = [NSColor colorWithRed:0.0
                                       green:0.478
                                        blue:1.0
                                       alpha:0.4];
    _glowColorInactive = [NSColor clearColor];

    _cornerRadius = 10.0;
    _isManaging = NO;
  }
  return self;
}

- (BorderFrameWindow *)frameForWindow:(NSWindow *)window {
  if (!window)
    return nil;
  return [self.windowToFrameMap objectForKey:window];
}

- (BorderFrameWindow *)createFrameForWindow:(NSWindow *)window {
  if (!window)
    return nil;

  // Check if eligible
  if (!macwmfx_isStandardAppWindow(window))
    return nil;
  if (!window.isVisible)
    return nil;
  if (macwmfx_isWindowFullscreen(window))
    return nil;
  if ([self.windowsInFullscreenTransition containsObject:window])
    return nil;

  // Check if already exists
  BorderFrameWindow *existing = [self.windowToFrameMap objectForKey:window];
  if (existing) {
    if (!existing.isVisible) {
      [existing updateFrameToMatchTarget];
      existing.alphaValue = 1.0;
      [existing attachToTargetWindow];
      [existing updateColorForFocusState];
    }
    return existing.isVisible ? existing : nil;
  }

  // Validate window frame
  NSRect windowFrame = window.frame;
  if (windowFrame.size.width <= 0 || windowFrame.size.height <= 0)
    return nil;

  // Create new frame window
  BorderFrameWindow *frameWindow =
      [[BorderFrameWindow alloc] initWithTargetWindow:window];
  if (!frameWindow)
    return nil;

  // Apply global configuration
  frameWindow.borderThickness = self.borderEnabled ? self.borderThickness : 0;
  frameWindow.borderColorActive = self.borderColorActive;
  frameWindow.borderColorInactive = self.borderColorInactive;
  frameWindow.shadowEnabled = self.shadowEnabled;
  frameWindow.shadowRadius = self.shadowRadius;
  frameWindow.shadowColor = self.shadowColor;
  frameWindow.glowEnabled = self.glowEnabled;
  frameWindow.glowRadius = self.glowRadius;
  frameWindow.glowColorActive = self.glowColorActive;
  frameWindow.glowColorInactive = self.glowColorInactive;
  frameWindow.cornerRadius = self.cornerRadius;

  // Store and attach
  [self.windowToFrameMap setObject:frameWindow forKey:window];
  [frameWindow attachToTargetWindow];
  [frameWindow updateColorForFocusState];

  MACWMFX_LOG_INFO(macwmfx_log_frame, "Created frame for window %ld",
                   (long)window.windowNumber);

  return frameWindow;
}

- (void)updateFrameForWindow:(NSWindow *)window {
  if (!window || !window.isVisible)
    return;

  // Handle fullscreen
  BOOL isFullscreen =
      macwmfx_isWindowFullscreen(window) ||
      [self.windowsInFullscreenTransition containsObject:window];
  if (isFullscreen) {
    BorderFrameWindow *frame = [self.windowToFrameMap objectForKey:window];
    if (frame) {
      if (frame.isVisible)
        [frame orderOut:nil];
      if (frame.parentWindow == window)
        [window removeChildWindow:frame];
    }
    return;
  }

  BorderFrameWindow *frame = [self.windowToFrameMap objectForKey:window];
  if (frame && frame.isVisible) {
    [frame updateFrameToMatchTarget];
    [frame updateColorForFocusState];

    // Ensure attached
    if (!frame.parentWindow) {
      [frame attachToTargetWindow];
    }
  } else if (macwmfx_isStandardAppWindow(window)) {
    [self createFrameForWindow:window];
  }
}

- (void)removeFrameForWindow:(NSWindow *)window {
  if (!window)
    return;

  BorderFrameWindow *frame = [self.windowToFrameMap objectForKey:window];
  if (frame) {
    @try {
      if (frame.parentWindow == window) {
        [window removeChildWindow:frame];
      }
      [frame close];
      [self.windowToFrameMap removeObjectForKey:window];
    } @catch (NSException *e) {
      @try {
        [self.windowToFrameMap removeObjectForKey:window];
      } @catch (NSException *e2) {
      }
    }
  }

  MACWMFX_LOG_DEBUG(macwmfx_log_frame, "Removed frame for window");
}

- (void)updateAllFrames {
  for (NSWindow *window in [NSApp windows]) {
    if (macwmfx_isStandardAppWindow(window) && window.isVisible) {
      BorderFrameWindow *frame = [self.windowToFrameMap objectForKey:window];
      if (frame) {
        // Apply current configuration
        frame.borderThickness = self.borderEnabled ? self.borderThickness : 0;
        frame.borderColorActive = self.borderColorActive;
        frame.borderColorInactive = self.borderColorInactive;
        frame.shadowEnabled = self.shadowEnabled;
        frame.shadowRadius = self.shadowRadius;
        frame.shadowColor = self.shadowColor;
        frame.glowEnabled = self.glowEnabled;
        frame.glowRadius = self.glowRadius;
        frame.glowColorActive = self.glowColorActive;
        frame.glowColorInactive = self.glowColorInactive;
        frame.cornerRadius = self.cornerRadius;

        [frame updateFrameToMatchTarget];
        [frame updateColorForFocusState];
      } else {
        [self createFrameForWindow:window];
      }
    }
  }
}

- (void)startManaging {
  if (self.isManaging)
    return;
  self.isManaging = YES;

  NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
  NSOperationQueue *mainQueue = [NSOperationQueue mainQueue];

  // Focus change notifications
  void (^focusHandler)(NSNotification *) = ^(NSNotification *note) {
    @autoreleasepool {
      NSWindow *window = note.object;
      if (!window || ![window isKindOfClass:[NSWindow class]])
        return;
      if ([window isKindOfClass:[BorderFrameWindow class]])
        return;

      @try {
        (void)window.isVisible;
      } @catch (NSException *e) {
        return;
      }

      BorderFrameWindow *frame = [self.windowToFrameMap objectForKey:window];
      if (frame && [frame isKindOfClass:[BorderFrameWindow class]]) {
        @try {
          [frame updateColorForFocusState];
        } @catch (NSException *e) {
        }
      }
    }
  };

  [center addObserverForName:NSWindowDidBecomeKeyNotification
                      object:nil
                       queue:mainQueue
                  usingBlock:focusHandler];
  [center addObserverForName:NSWindowDidResignKeyNotification
                      object:nil
                       queue:mainQueue
                  usingBlock:focusHandler];
  [center addObserverForName:NSWindowDidBecomeMainNotification
                      object:nil
                       queue:mainQueue
                  usingBlock:focusHandler];
  [center addObserverForName:NSWindowDidResignMainNotification
                      object:nil
                       queue:mainQueue
                  usingBlock:focusHandler];

  // Resize/move notifications
  void (^resizeMoveHandler)(NSNotification *) = ^(NSNotification *note) {
    @autoreleasepool {
      NSWindow *window = note.object;
      if (!window || ![window isKindOfClass:[NSWindow class]])
        return;
      if ([window isKindOfClass:[BorderFrameWindow class]])
        return;

      @try {
        if (macwmfx_isWindowFullscreen(window) ||
            [self.windowsInFullscreenTransition containsObject:window])
          return;
        (void)window.frame;
      } @catch (NSException *e) {
        return;
      }

      BorderFrameWindow *frame = [self.windowToFrameMap objectForKey:window];
      if (frame && frame.isVisible) {
        @try {
          [frame updateFrameToMatchTarget];
        } @catch (NSException *e) {
        }
      } else {
        [self updateFrameForWindow:window];
      }
    }
  };

  [center addObserverForName:NSWindowDidResizeNotification
                      object:nil
                       queue:mainQueue
                  usingBlock:resizeMoveHandler];
  [center addObserverForName:NSWindowDidMoveNotification
                      object:nil
                       queue:mainQueue
                  usingBlock:resizeMoveHandler];

  // Fullscreen notifications
  [center addObserverForName:NSWindowWillEnterFullScreenNotification
                      object:nil
                       queue:mainQueue
                  usingBlock:^(NSNotification *note) {
                    @autoreleasepool {
                      NSWindow *window = note.object;
                      if (!window || ![window isKindOfClass:[NSWindow class]])
                        return;

                      @try {
                        (void)window.isVisible;
                      } @catch (NSException *e) {
                        return;
                      }

                      [self.windowsInFullscreenTransition addObject:window];

                      BorderFrameWindow *frame =
                          [self.windowToFrameMap objectForKey:window];
                      if (frame && frame.isVisible) {
                        @try {
                          [frame orderOut:nil];
                        } @catch (NSException *e) {
                        }
                      }
                    }
                  }];

  [center addObserverForName:NSWindowDidEnterFullScreenNotification
                      object:nil
                       queue:mainQueue
                  usingBlock:^(NSNotification *note) {
                    @autoreleasepool {
                      NSWindow *window = note.object;
                      if (!window || ![window isKindOfClass:[NSWindow class]])
                        return;

                      @try {
                        (void)window.isVisible;
                      } @catch (NSException *e) {
                        return;
                      }

                      [self.windowsInFullscreenTransition removeObject:window];

                      BorderFrameWindow *frame =
                          [self.windowToFrameMap objectForKey:window];
                      if (frame) {
                        @try {
                          if (frame.isVisible)
                            [frame orderOut:nil];
                          if (frame.parentWindow == window)
                            [window removeChildWindow:frame];
                          frame.alphaValue = 0.0;
                        } @catch (NSException *e) {
                        }
                      }
                    }
                  }];

  [center addObserverForName:NSWindowWillExitFullScreenNotification
                      object:nil
                       queue:mainQueue
                  usingBlock:^(NSNotification *note) {
                    @autoreleasepool {
                      NSWindow *window = note.object;
                      if (!window || ![window isKindOfClass:[NSWindow class]])
                        return;

                      @try {
                        (void)window.isVisible;
                      } @catch (NSException *e) {
                        return;
                      }

                      [self.windowsInFullscreenTransition addObject:window];
                    }
                  }];

  [center
      addObserverForName:NSWindowDidExitFullScreenNotification
                  object:nil
                   queue:mainQueue
              usingBlock:^(NSNotification *note) {
                @autoreleasepool {
                  NSWindow *window = note.object;
                  if (!window || ![window isKindOfClass:[NSWindow class]])
                    return;

                  @try {
                    (void)window.isVisible;
                  } @catch (NSException *e) {
                    return;
                  }

                  [self.windowsInFullscreenTransition removeObject:window];

                  if (macwmfx_isStandardAppWindow(window) && window.isVisible) {
                    __weak NSWindow *weakWindow = window;
                    dispatch_after(
                        dispatch_time(DISPATCH_TIME_NOW,
                                      (int64_t)(0.3 * NSEC_PER_SEC)),
                        dispatch_get_main_queue(), ^{
                          @autoreleasepool {
                            @try {
                              if (!weakWindow ||
                                  ![weakWindow isKindOfClass:[NSWindow class]])
                                return;
                              (void)weakWindow.isVisible;
                              if (!macwmfx_isWindowFullscreen(weakWindow) &&
                                  ![self.windowsInFullscreenTransition
                                      containsObject:weakWindow]) {
                                [self createFrameForWindow:weakWindow];
                              }
                            } @catch (NSException *e) {
                            }
                          }
                        });
                  }
                }
              }];

  // Window close notification
  [center addObserverForName:NSWindowWillCloseNotification
                      object:nil
                       queue:mainQueue
                  usingBlock:^(NSNotification *note) {
                    @autoreleasepool {
                      NSWindow *window = note.object;
                      if (!window || ![window isKindOfClass:[NSWindow class]])
                        return;

                      [self removeFrameForWindow:window];
                    }
                  }];

  MACWMFX_LOG_INFO(macwmfx_log_frame,
                   "FrameWindowManager started managing windows");
}

- (void)stopManaging {
  if (!self.isManaging)
    return;
  self.isManaging = NO;

  [[NSNotificationCenter defaultCenter] removeObserver:self];

  // Remove all frames
  for (NSWindow *window in [[self.windowToFrameMap keyEnumerator] allObjects]) {
    [self removeFrameForWindow:window];
  }

  MACWMFX_LOG_INFO(macwmfx_log_frame,
                   "FrameWindowManager stopped managing windows");
}

@end
