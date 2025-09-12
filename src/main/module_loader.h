//
//  module_loader.h
//  macwmfx
//
//  Created by Alex "aspauldingcode" on 01/09/25.
//  Copyright (c) 2025 Alex "aspauldingcode". All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * ModuleLoader - Dynamic module loading system
 *
 * This system replaces feature flags with import-based module loading.
 * Features are loaded only when explicitly imported, similar to how
 * Nix handles optional dependencies.
 */

/**
 * Module protocol that all macwmfx modules must implement
 */
@protocol macwmfxModule <NSObject>

// Required methods
- (void)start;
- (void)stop;
- (BOOL)isEnabled;

@optional
// Optional methods
- (void)reloadConfiguration;
- (void)updateConfiguration:(NSDictionary *)config;
- (void)updateWindow:(NSWindow *)window;

@end

// Module loader interface
@interface ModuleLoader : NSObject

// Singleton access
+ (instancetype)sharedLoader;

// Module management
- (BOOL)loadModule:(NSString *)moduleName;
- (BOOL)unloadModule:(NSString *)moduleName;
- (BOOL)isModuleLoaded:(NSString *)moduleName;
- (NSArray<NSString *> *)getLoadedModules;
- (NSArray<NSString *> *)getAvailableModules;

// Dependency resolution
- (BOOL)loadModuleWithDependencies:(NSString *)moduleName;
- (NSArray<NSString *> *)resolveDependencies:(NSString *)moduleName;

// Module discovery
- (NSArray<NSString *> *)discoverAvailableModules;
- (NSDictionary *)getModuleInfo:(NSString *)moduleName;

// Configuration integration
- (void)loadModulesFromConfiguration:(NSDictionary *)config;
- (NSDictionary *)getModuleConfigurations;

// Runtime control
- (BOOL)enableModule:(NSString *)moduleName;
- (BOOL)disableModule:(NSString *)moduleName;
- (void)reloadAllModules;
- (void)updateAllWindows;

@end

// Convenience macros for module registration
#define MACWMFX_MODULE_REGISTER(ModuleClass) \
    + (void)load { \
        [[ModuleLoader sharedLoader] registerModule:[ModuleClass class]]; \
    }

#define MACWMFX_MODULE_DEPENDENCY(ModuleName) \
    + (NSArray<NSString *> *)moduleDependencies { \
        return @[ModuleName]; \
    }

NS_ASSUME_NONNULL_END
