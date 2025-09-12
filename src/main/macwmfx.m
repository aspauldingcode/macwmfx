//
//  macwmfx.m
//  macwmfx
//
//  Created by Alex "aspauldingcode" on 01/09/25.
//  Copyright (c) 2025 Alex "aspauldingcode". All rights reserved.
//

#import "macwmfx.h"
#import "../shared/headers/configParser.h"
#import "../shared/headers/macwmfx_globals.h"
#import "../shared/macwmfx_logging.h"
#import "module_loader.h"

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
// #import "../modules/windows/features/windowTrafficLights/disableTrafficLights.m"
// #import "../modules/windows/features/windowTitlebar/DisableTitleBars.m"
// #import "../modules/windows/features/windowTitlebar/TitlebarAesthetics.m"
// #import "../modules/windows/features/windowTitlebar/ForceCustomTitle.m"
// #import "../modules/windows/features/windowSizeContraints/DisableResizeConstraints.m"

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
// #import "../modules/windows/features/windowOutline/DisableWindowCornerRadiusMask.m"
// #import "../modules/windows/features/windowShadow/ShadowColor.mm"
// #import "../modules/windows/features/windowTitlebar/DisableTitleBars.m"
// #import "../modules/windows/features/windowTitlebar/ForceClassicTitlebars.m"
// #import "../modules/windows/features/windowTrafficLights/TrafficLightsController.m"
// #import "../modules/windows/features/windowTransparency/OpacityController.m"

// =============================================================================

@interface macwmfx ()
@property (nonatomic, strong) ModuleLoader *moduleLoader;
@property (nonatomic, assign) BOOL isRunning;
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

        self.moduleLoader = [ModuleLoader sharedLoader];
        self.isRunning = NO;

        MACWMFX_LOG_INFO(macwmfx_log_general, "macwmfx main module initialized");
    }
    return self;
}

- (void)start {
    if (self.isRunning) return;

    MACWMFX_LOG_INFO(macwmfx_log_general, "Starting macwmfx");
    [self loadConfiguration];
    [self loadModules];
    self.isRunning = YES;
    MACWMFX_LOG_INFO(macwmfx_log_general, "macwmfx started successfully");
}

- (void)stop {
    if (!self.isRunning) return;

    MACWMFX_LOG_INFO(macwmfx_log_general, "Stopping macwmfx");
    [self unloadModules];
    self.isRunning = NO;
    MACWMFX_LOG_INFO(macwmfx_log_general, "macwmfx stopped");
}

- (BOOL)isRunning { return self.isRunning; }

- (void)loadModules {
    MACWMFX_LOG_INFO(macwmfx_log_general, "Loading modules via ModuleLoader");

    // DEVELOPMENT MODE: All modules are disabled by default
    // Uncomment module imports above to enable specific modules

    // Get available modules (those that were compiled in)
    NSArray<NSString *> *availableModules = [self.moduleLoader getAvailableModules];
    MACWMFX_LOG_INFO(macwmfx_log_general, "Available modules: %@", availableModules);

    // Load modules based on configuration
    [self.moduleLoader loadModulesFromConfiguration:[self getCurrentConfig]];

    NSArray<NSString *> *loadedModules = [self.moduleLoader getLoadedModules];
    MACWMFX_LOG_INFO(macwmfx_log_general, "Loaded %lu modules: %@", (unsigned long)loadedModules.count, loadedModules);
}

- (void)unloadModules {
    NSArray<NSString *> *loadedModules = [self.moduleLoader getLoadedModules];
    MACWMFX_LOG_INFO(macwmfx_log_general, "Unloading %lu modules", (unsigned long)loadedModules.count);

    for (NSString *moduleName in loadedModules) {
        [self.moduleLoader unloadModule:moduleName];
    }

    MACWMFX_LOG_INFO(macwmfx_log_general, "All modules unloaded");
}

- (NSArray<id> *)getLoadedModules {
    return [self.moduleLoader getLoadedModules];
}

- (NSArray<id> *)getAvailableModules {
    return [self.moduleLoader getAvailableModules];
}

- (void)loadConfiguration {
    MACWMFX_LOG_INFO(macwmfx_log_config, "Loading configuration");
    [[ConfigParser sharedInstance] loadConfig];
}

- (NSDictionary *)getCurrentConfig {
    // Convert global config variables to dictionary format
    return @{
        @"window": @{
            @"shadow": @{@"enabled": @(gShadowConfig.enabled)},
            @"trafficLights": @{@"enabled": @(gTrafficLightsConfig.enabled)},
            @"titlebar": @{@"enabled": @(gTitlebarConfig.enabled)},
            @"outline": @{@"enabled": @(gOutlineConfig.enabled)}
        },
        @"menubar": @{
            @"noMenubar": @{@"enabled": @NO}, // Add to globals if needed
            @"ribbonbar": @{@"enabled": @NO}  // Add to globals if needed
        },
        @"dock": @{
            @"disableDock": @{@"enabled": @NO} // Add to globals if needed
        },
        @"spaces": @{
            @"disableSpaces": @{@"enabled": @NO}, // Add to globals if needed
            @"renameSpaces": @{@"enabled": @NO}   // Add to globals if needed
        }
    };
}

- (void)reloadConfiguration {
    MACWMFX_LOG_INFO(macwmfx_log_config, "Reloading configuration");
    [self loadConfiguration];
    [self.moduleLoader reloadAllModules];
    [self updateAllWindows];
}

- (void)saveConfiguration { /* no-op */ }

- (void)updateAllWindows {
    dispatch_async(dispatch_get_main_queue(), ^{
        MACWMFX_LOG_DEBUG(macwmfx_log_window, "Updating all windows");
        for (NSWindow *window in [NSApp windows]) [self updateWindow:window];
    });
}

- (void)updateWindow:(NSWindow *)window {
    [self.moduleLoader updateAllWindows];
}

#pragma mark - Runtime Module Control

- (BOOL)enableModule:(NSString *)moduleName {
    return [self.moduleLoader enableModule:moduleName];
}

- (BOOL)disableModule:(NSString *)moduleName {
    return [self.moduleLoader disableModule:moduleName];
}

- (BOOL)isModuleEnabled:(NSString *)moduleName {
    return [self.moduleLoader isModuleLoaded:moduleName];
}

- (NSDictionary *)getModuleInfo:(NSString *)moduleName {
    return [self.moduleLoader getModuleInfo:moduleName];
}

- (NSDictionary *)getAllModuleInfo {
    return [self.moduleLoader getModuleConfigurations];
}

#pragma mark - Legacy Feature Methods (for compatibility)

- (void)enableFeature:(NSString *)featureName {
    [self enableModule:featureName];
}

- (void)disableFeature:(NSString *)featureName {
    [self disableModule:featureName];
}

- (BOOL)isFeatureEnabled:(NSString *)featureName {
    return [self isModuleEnabled:featureName];
}

- (void)setupSystemHooks {
    MACWMFX_LOG_INFO(macwmfx_log_general, "Setting up system hooks");
    // This would be implemented if needed for legacy compatibility
}

- (void)removeSystemHooks {
    MACWMFX_LOG_INFO(macwmfx_log_general, "Removing system hooks");
    // This would be implemented if needed for legacy compatibility
}

@end
