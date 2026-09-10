//
//  macwmfx.m
//  macwmfx
//
//  Created by Alex "aspauldingcode" on 01/09/25.
//  Copyright (c) 2025 Alex "aspauldingcode". All rights reserved.
//

#import "macwmfx.h"
#import "../shared/headers/macwmfx_Common.h"
#import "../shared/macwmfx_logging.h"
#import "macwmfx_Styler.h"

// =============================================================================
// MODULE IMPORTS - Control which modules are compiled
// =============================================================================
// Comment/uncomment these imports to enable/disable modules at compile time
// Similar to Nix: imports = [ module1.nix module2.nix #unused.nix ];
//
// DEVELOPMENT MODE: All modules disabled by default
// Uncomment modules one-by-one as you develop and test them

// Window Management Modules
// #import "../modules/windows/features/borders/WindowBorderModule.h"
// #import "../modules/windows/features/windowShadow/DisableWindowShadow.m"
// #import
// "../modules/windows/features/windowTrafficLights/disableTrafficLights.m"
// #import "../modules/windows/features/windowTitlebar/DisableTitleBars.m"
// #import "../modules/windows/features/windowTitlebar/TitlebarAesthetics.m"
// #import "../modules/windows/features/windowTitlebar/ForceCustomTitle.m"
// #import
// "../modules/windows/features/windowSizeContraints/DisableResizeConstraints.m"

// Menubar Modules
// #import "../modules/menubar/features/NoMenubar.m"
// #import "../modules/menubar/features/ribbonbar/RibbonBar.m"

// Dock Modules
// #import "../modules/dock/features/DisableDock.m"

// Spaces Modules
// #import "../modules/spaces/features/DisableSpaces.m"
// #import "../modules/spaces/features/RenameSpaces.m"
// #import "../modules/spaces/features/InstantFullscreenTransition.m"

// Additional Window Modules (currently disabled)
// #import "../modules/windows/features/windowBlur/BlurController.m"
// #import "../modules/windows/features/windowTransparency/OpacityController.m"
// #import "../modules/windows/features/windowBehavior/AlwaysOnTopController.m"
// #import "../modules/windows/features/windowBehavior/GoodbyeForGood.m"
// #import "../modules/windows/features/windowAnimations/windowRotation.m"
// #import "../modules/windows/features/windowMaskShapes/WindowStar.m"
// #import "../modules/windows/features/windowOutline/WindowBordersCenterline.m"
// #import "../modules/windows/features/windowOutline/WindowBordersInline.mm"
// #import "../modules/windows/features/windowOutline/WindowBordersOutline.mm"
// #import
// "../modules/windows/features/windowOutline/DisableWindowCornerRadiusMask.m"
// #import "../modules/windows/features/windowShadow/ShadowColor.mm"
// #import "../modules/windows/features/windowTitlebar/DisableTitleBars.m"
// #import "../modules/windows/features/windowTitlebar/ForceClassicTitlebars.m"
// #import
// "../modules/windows/features/windowTrafficLights/TrafficLightsController.m"
// #import "../modules/windows/features/windowTransparency/OpacityController.m"

// =============================================================================

@interface macwmfx ()
@property(nonatomic, assign) BOOL isRunning;
@end

@implementation macwmfx

+ (instancetype)sharedInstance {
  static macwmfx *sharedInstance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedInstance = [[macwmfx alloc] init];
  });
  return sharedInstance;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    // Initialize logging system
    macwmfx_logging_init();
    self.isRunning = NO;
    MACWMFX_LOG_INFO(macwmfx_log_general, "macwmfx main module initialized");
  }
  return self;
}

- (void)start {
  if (self.isRunning)
    return;

  // Safety check: ensure we are in a GUI application
  // Safety check: ensure we are in a GUI application
  if (!NSApp) {
    dispatch_async(dispatch_get_main_queue(), ^{
      [self start];
    });
    return;
  }

  MACWMFX_LOG_INFO(macwmfx_log_general, "Starting macwmfx engine");
  [self loadConfiguration];
  [self setupWindowHooks];
  self.isRunning = YES;

  [macwmfxStyler refreshAllWindows];
  MACWMFX_LOG_INFO(macwmfx_log_general, "macwmfx started successfully");
}

- (void)stop {
  if (!self.isRunning)
    return;

  MACWMFX_LOG_INFO(macwmfx_log_general, "Stopping macwmfx");
  self.isRunning = NO;
  MACWMFX_LOG_INFO(macwmfx_log_general, "macwmfx stopped");
}

- (BOOL)isRunning {
  return _isRunning;
}

- (void)loadConfiguration {
  MACWMFX_LOG_INFO(macwmfx_log_config, "Loading macwmfx configuration");
  [[ConfigParser sharedInstance] loadConfig];
}

- (void)reloadConfiguration {
  MACWMFX_LOG_INFO(macwmfx_log_config, "Reloading macwmfx configuration");
  [self loadConfiguration];
  [macwmfxStyler refreshAllWindows];
}

- (void)setupWindowHooks {
  [[NSNotificationCenter defaultCenter]
      addObserver:self
         selector:@selector(handleWindowDidBecomeKey:)
             name:NSWindowDidBecomeKeyNotification
           object:nil];
  [[NSNotificationCenter defaultCenter]
      addObserver:self
         selector:@selector(handleWindowDidResignKey:)
             name:NSWindowDidResignKeyNotification
           object:nil];
}

- (void)handleWindowDidBecomeKey:(NSNotification *)notification {
  [macwmfxStyler applyStyleToWindow:notification.object];
}

- (void)handleWindowDidResignKey:(NSNotification *)notification {
  [macwmfxStyler applyStyleToWindow:notification.object];
}

- (void)saveConfiguration { /* no-op */
}

@end
