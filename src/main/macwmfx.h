//
//  macwmfx.h
//  macwmfx
//
//  Created by Alex "aspauldingcode" on 01/09/25.
//  Copyright (c) 2025 Alex "aspauldingcode". All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol macwmfxModule;
@class ConfigManager;
@class WindowManager;
@class DockManager;
@class MenubarManager;
@class SpacesManager;

/**
 * macwmfx - Main orchestrator class
 *
 * This is the main entry point for the macwmfx tweak.
 * It manages the lifecycle of all modules and handles
 * the overall coordination of window management effects.
 *
 * The class is designed to be a singleton that can be
 * accessed from anywhere in the tweak to manage modules
 * and configuration.
 */
@interface macwmfx : NSObject

// Singleton access
+ (instancetype)sharedInstance;

// Core managers
@property (nonatomic, strong, readonly) ConfigManager *configManager;
@property (nonatomic, strong, readonly) WindowManager *windowManager;
@property (nonatomic, strong, readonly) DockManager *dockManager;
@property (nonatomic, strong, readonly) MenubarManager *menubarManager;
@property (nonatomic, strong, readonly) SpacesManager *spacesManager;

// Lifecycle management
- (void)start;
- (void)stop;

// Module management
- (void)loadModules;
- (void)unloadModules;
- (NSArray<id> *)getLoadedModules;

// Configuration
- (void)loadConfiguration;
- (void)reloadConfiguration;
- (void)saveConfiguration;

// Window management
- (void)updateAllWindows;
- (void)updateWindow:(NSWindow *)window;

// Feature control
- (void)enableFeature:(NSString *)featureName;
- (void)disableFeature:(NSString *)featureName;
- (BOOL)isFeatureEnabled:(NSString *)featureName;

// System integration
- (void)setupSystemHooks;
- (void)removeSystemHooks;

@end

NS_ASSUME_NONNULL_END
