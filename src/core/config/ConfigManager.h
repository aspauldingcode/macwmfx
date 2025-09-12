//
//  ConfigManager.h
//  macwmfx
//
//  Created by Alex "aspauldingcode" on 01/09/25.
//  Copyright (c) 2025 Alex "aspauldingcode". All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * ConfigManager - Centralized configuration management
 *
 * This class handles all configuration loading, parsing, and hot-reloading
 * for the macwmfx system. It replaces the old ConfigParser with a cleaner
 * interface and better separation of concerns.
 */
@interface ConfigManager : NSObject

// Configuration access
@property (nonatomic, strong, readonly) NSDictionary *configuration;
@property (nonatomic, strong, readonly) NSString *configPath;

// Hot-reload support
@property (nonatomic, assign) BOOL hotReloadEnabled;
@property (nonatomic, assign) NSTimeInterval hotReloadInterval;

// Initialization
- (instancetype)init;
- (instancetype)initWithConfigPath:(NSString *)configPath;

// Configuration loading
- (BOOL)loadConfiguration;
- (BOOL)loadConfigurationFromPath:(NSString *)path;
- (BOOL)saveConfiguration:(NSDictionary *)config;

// Configuration access
- (NSDictionary *)getConfiguration;
- (id)getValueForKey:(NSString *)key;
- (id)getValueForKeyPath:(NSString *)keyPath;

// Hot-reload management
- (void)startHotReload;
- (void)stopHotReload;
- (void)setHotReloadCallback:(void (^)(NSDictionary *newConfig))callback;

// Configuration validation
- (BOOL)validateConfiguration:(NSDictionary *)config;
- (NSDictionary *)getDefaultConfiguration;

// Utility methods
- (void)resetToDefaults;
- (BOOL)backupConfiguration;
- (BOOL)restoreConfiguration;

@end

NS_ASSUME_NONNULL_END
