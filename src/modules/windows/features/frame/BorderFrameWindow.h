/**
 * BorderFrameWindow.h - Custom Border/Shadow Window for macwmfx
 *
 * Creates a child window that renders behind the target window to provide
 * custom borders, shadows, and glow effects. This is the proven approach
 * from apple-sharpener.
 *
 * @author Alex "aspauldingcode"
 * @version 1.0
 */

#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * BorderFrameWindow - A custom NSWindow subclass that provides visual
 * borders and shadows for target windows.
 *
 * This window:
 * - Is always positioned behind its target window
 * - Follows the target window's movements
 * - Is invisible to mouse events
 * - Hides during fullscreen transitions
 */
@interface BorderFrameWindow : NSWindow

/// The target window this frame belongs to
@property(nonatomic, weak, nullable) NSWindow *targetWindow;

/// Border configuration
@property(nonatomic, assign) CGFloat borderThickness;
@property(nonatomic, strong, nullable) NSColor *borderColorActive;
@property(nonatomic, strong, nullable) NSColor *borderColorInactive;

/// Shadow configuration
@property(nonatomic, assign) BOOL shadowEnabled;
@property(nonatomic, assign) CGFloat shadowRadius;
@property(nonatomic, strong, nullable) NSColor *shadowColor;
@property(nonatomic, assign) NSPoint shadowOffset;
@property(nonatomic, assign) CGFloat shadowOpacity;

/// Glow configuration
@property(nonatomic, assign) BOOL glowEnabled;
@property(nonatomic, assign) CGFloat glowRadius;
@property(nonatomic, strong, nullable) NSColor *glowColorActive;
@property(nonatomic, strong, nullable) NSColor *glowColorInactive;
@property(nonatomic, assign) BOOL glowAnimated;

/// Corner radius
@property(nonatomic, assign) CGFloat cornerRadius;

/**
 * Initialize with target window
 */
- (instancetype)initWithTargetWindow:(NSWindow *)targetWindow;

/**
 * Update frame position to match target window
 */
- (void)updateFrameToMatchTarget;

/**
 * Update colors based on target window focus state
 */
- (void)updateColorForFocusState;

/**
 * Check if frame should hide for fullscreen
 */
- (BOOL)shouldHideForFullscreen;

/**
 * Attach to target window as child
 */
- (void)attachToTargetWindow;

/**
 * Detach from target window
 */
- (void)detachFromTargetWindow;

@end

#pragma mark - Frame Window Manager

/**
 * FrameWindowManager - Singleton manager for all BorderFrameWindows
 *
 * Handles:
 * - Window-to-frame mapping
 * - Automatic frame creation when windows appear
 * - Cleanup when windows close
 * - Global configuration updates
 */
@interface FrameWindowManager : NSObject

/// Singleton instance
+ (instancetype)sharedManager;

/// Global border configuration
@property(nonatomic, assign) BOOL borderEnabled;
@property(nonatomic, assign) CGFloat borderThickness;
@property(nonatomic, strong, nullable) NSColor *borderColorActive;
@property(nonatomic, strong, nullable) NSColor *borderColorInactive;

/// Global shadow configuration
@property(nonatomic, assign) BOOL shadowEnabled;
@property(nonatomic, assign) CGFloat shadowRadius;
@property(nonatomic, strong, nullable) NSColor *shadowColor;

/// Global glow configuration
@property(nonatomic, assign) BOOL glowEnabled;
@property(nonatomic, assign) CGFloat glowRadius;
@property(nonatomic, strong, nullable) NSColor *glowColorActive;
@property(nonatomic, strong, nullable) NSColor *glowColorInactive;

/// Global corner radius (for frame shape)
@property(nonatomic, assign) CGFloat cornerRadius;

/**
 * Create or get existing frame for a window
 */
- (nullable BorderFrameWindow *)frameForWindow:(NSWindow *)window;

/**
 * Create frame for a window if eligible
 */
- (nullable BorderFrameWindow *)createFrameForWindow:(NSWindow *)window;

/**
 * Update frame for a window
 */
- (void)updateFrameForWindow:(NSWindow *)window;

/**
 * Remove frame for a window
 */
- (void)removeFrameForWindow:(NSWindow *)window;

/**
 * Update all frames with current configuration
 */
- (void)updateAllFrames;

/**
 * Start managing windows (install notification observers)
 */
- (void)startManaging;

/**
 * Stop managing windows
 */
- (void)stopManaging;

@end

NS_ASSUME_NONNULL_END
