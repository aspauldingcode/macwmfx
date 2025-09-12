//
//  module_loader.m
//  macwmfx
//
//  Created by Alex "aspauldingcode" on 01/09/25.
//  Copyright (c) 2025 Alex "aspauldingcode". All rights reserved.
//

#import "module_loader.h"
#import "../shared/macwmfx_logging.h"

@interface ModuleLoader ()
@property (nonatomic, strong) NSMutableDictionary<NSString *, id<macwmfxModule>> *loadedModules;
@property (nonatomic, strong) NSMutableDictionary<NSString *, Class> *availableModules;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSArray<NSString *> *> *moduleDependencies;
@end

@implementation ModuleLoader

+ (instancetype)sharedLoader {
    static ModuleLoader *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _loadedModules = [NSMutableDictionary dictionary];
        _availableModules = [NSMutableDictionary dictionary];
        _moduleDependencies = [NSMutableDictionary dictionary];

        MACWMFX_LOG_INFO(macwmfx_log_general, "ModuleLoader initialized");
    }
    return self;
}

#pragma mark - Module Registration

- (void)registerModule:(Class)moduleClass {
    if (![moduleClass conformsToProtocol:@protocol(macwmfxModule)]) {
        MACWMFX_LOG_ERROR(macwmfx_log_general, "Module class %@ does not conform to macwmfxModule protocol", NSStringFromClass(moduleClass));
        return;
    }

    NSString *moduleName = NSStringFromClass(moduleClass);
    self.availableModules[moduleName] = moduleClass;

    // Check for dependencies
    if ([moduleClass respondsToSelector:@selector(moduleDependencies)]) {
        NSArray<NSString *> *dependencies = (NSArray<NSString *> *)[moduleClass moduleDependencies];
        if (dependencies.count > 0) {
            self.moduleDependencies[moduleName] = dependencies;
            MACWMFX_LOG_INFO(macwmfx_log_general, "Registered module %@ with dependencies: %@", moduleName, dependencies);
        }
    }

    MACWMFX_LOG_INFO(macwmfx_log_general, "Registered module: %@", moduleName);
}

#pragma mark - Module Management

- (BOOL)loadModule:(NSString *)moduleName {
    if ([self isModuleLoaded:moduleName]) {
        MACWMFX_LOG_INFO(macwmfx_log_general, "Module %@ is already loaded", moduleName);
        return YES;
    }

    Class moduleClass = self.availableModules[moduleName];
    if (!moduleClass) {
        MACWMFX_LOG_ERROR(macwmfx_log_general, "Module %@ is not available (not compiled in)", moduleName);
        return NO;
    }

    // Check dependencies first
    if (![self loadModuleDependencies:moduleName]) {
        MACWMFX_LOG_ERROR(macwmfx_log_general, "Failed to load dependencies for module %@", moduleName);
        return NO;
    }

    // Create and start the module
    id<macwmfxModule> module = [[moduleClass alloc] init];
    if (!module) {
        MACWMFX_LOG_ERROR(macwmfx_log_general, "Failed to create instance of module %@", moduleName);
        return NO;
    }

    [module start];
    self.loadedModules[moduleName] = module;

    MACWMFX_LOG_INFO(macwmfx_log_general, "Successfully loaded module: %@", moduleName);
    return YES;
}

- (BOOL)unloadModule:(NSString *)moduleName {
    id<macwmfxModule> module = self.loadedModules[moduleName];
    if (!module) {
        MACWMFX_LOG_INFO(macwmfx_log_general, "Module %@ is not loaded", moduleName);
        return YES;
    }

    [module stop];
    [self.loadedModules removeObjectForKey:moduleName];

    MACWMFX_LOG_INFO(macwmfx_log_general, "Successfully unloaded module: %@", moduleName);
    return YES;
}

- (BOOL)isModuleLoaded:(NSString *)moduleName {
    return self.loadedModules[moduleName] != nil;
}

- (NSArray<NSString *> *)getLoadedModules {
    return [self.loadedModules allKeys];
}

- (NSArray<NSString *> *)getAvailableModules {
    return [self.availableModules allKeys];
}

#pragma mark - Dependency Management

- (BOOL)loadModuleWithDependencies:(NSString *)moduleName {
    return [self loadModule:moduleName];
}

- (NSArray<NSString *> *)resolveDependencies:(NSString *)moduleName {
    return self.moduleDependencies[moduleName] ?: @[];
}

- (BOOL)loadModuleDependencies:(NSString *)moduleName {
    NSArray<NSString *> *dependencies = [self resolveDependencies:moduleName];

    for (NSString *dependency in dependencies) {
        if (![self loadModule:dependency]) {
            return NO;
        }
    }

    return YES;
}

#pragma mark - Module Discovery

- (NSArray<NSString *> *)discoverAvailableModules {
    return [self getAvailableModules];
}

- (NSDictionary *)getModuleInfo:(NSString *)moduleName {
    Class moduleClass = self.availableModules[moduleName];
    if (!moduleClass) {
        return nil;
    }

    id<macwmfxModule> module = self.loadedModules[moduleName];

    return @{
        @"name": moduleName,
        @"class": NSStringFromClass(moduleClass),
        @"loaded": @(module != nil),
        @"enabled": @(module ? [module isEnabled] : NO),
        @"dependencies": [self resolveDependencies:moduleName]
    };
}

#pragma mark - Configuration Integration

- (void)loadModulesFromConfiguration:(NSDictionary *)config {
    MACWMFX_LOG_INFO(macwmfx_log_general, "Loading modules from configuration");

    // Load window modules based on config
    NSDictionary *windowConfig = config[@"window"];
    if (windowConfig) {
        [self loadModuleIfAvailable:@"window.shadow" enabled:[windowConfig[@"shadow"][@"enabled"] boolValue]];
        [self loadModuleIfAvailable:@"window.trafficLights" enabled:[windowConfig[@"trafficLights"][@"enabled"] boolValue]];
        [self loadModuleIfAvailable:@"window.titlebar" enabled:[windowConfig[@"titlebar"][@"enabled"] boolValue]];
        [self loadModuleIfAvailable:@"window.outline" enabled:[windowConfig[@"outline"][@"enabled"] boolValue]];
    }

    // Load other module types
    NSDictionary *menubarConfig = config[@"menubar"];
    if (menubarConfig) {
        [self loadModuleIfAvailable:@"menubar.noMenubar" enabled:[menubarConfig[@"noMenubar"][@"enabled"] boolValue]];
        [self loadModuleIfAvailable:@"menubar.ribbonbar" enabled:[menubarConfig[@"ribbonbar"][@"enabled"] boolValue]];
    }

    NSDictionary *dockConfig = config[@"dock"];
    if (dockConfig) {
        [self loadModuleIfAvailable:@"dock.disableDock" enabled:[dockConfig[@"disableDock"][@"enabled"] boolValue]];
    }

    NSDictionary *spacesConfig = config[@"spaces"];
    if (spacesConfig) {
        [self loadModuleIfAvailable:@"spaces.disableSpaces" enabled:[spacesConfig[@"disableSpaces"][@"enabled"] boolValue]];
        [self loadModuleIfAvailable:@"spaces.renameSpaces" enabled:[spacesConfig[@"renameSpaces"][@"enabled"] boolValue]];
    }
}

- (void)loadModuleIfAvailable:(NSString *)moduleName enabled:(BOOL)enabled {
    if (enabled && [self.availableModules objectForKey:moduleName]) {
        [self loadModule:moduleName];
    } else if (!enabled && [self isModuleLoaded:moduleName]) {
        [self unloadModule:moduleName];
    }
}

- (NSDictionary *)getModuleConfigurations {
    NSMutableDictionary *configs = [NSMutableDictionary dictionary];

    for (NSString *moduleName in [self getAvailableModules]) {
        NSDictionary *info = [self getModuleInfo:moduleName];
        if (info) {
            configs[moduleName] = info;
        }
    }

    return [configs copy];
}

#pragma mark - Runtime Control

- (BOOL)enableModule:(NSString *)moduleName {
    if (![self.availableModules objectForKey:moduleName]) {
        MACWMFX_LOG_ERROR(macwmfx_log_general, "Cannot enable module %@ - not compiled in", moduleName);
        return NO;
    }

    return [self loadModule:moduleName];
}

- (BOOL)disableModule:(NSString *)moduleName {
    return [self unloadModule:moduleName];
}

- (void)reloadAllModules {
    MACWMFX_LOG_INFO(macwmfx_log_general, "Reloading all loaded modules");

    NSArray<NSString *> *loadedModules = [self getLoadedModules];
    for (NSString *moduleName in loadedModules) {
        id<macwmfxModule> module = self.loadedModules[moduleName];
        if ([module respondsToSelector:@selector(reloadConfiguration)]) {
            [module reloadConfiguration];
        }
    }
}

- (void)updateAllWindows {
    MACWMFX_LOG_INFO(macwmfx_log_general, "Updating all windows through loaded modules");

    for (id<macwmfxModule> module in [self.loadedModules allValues]) {
        if ([module respondsToSelector:@selector(updateWindow:)]) {
            // This would need to be called with actual window instances
            // For now, just log that the module supports window updates
            MACWMFX_LOG_DEBUG(macwmfx_log_general, "Module %@ supports window updates", NSStringFromClass([module class]));
        }
    }
}

@end
