//
//  WindowManager.h
//  macwmfx
//
//  Created by Alex "aspauldingcode" on 01/09/25.
//  Copyright (c) 2025 Alex "aspauldingcode". All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@class ConfigManager;

/**
 * WindowManager - Manages all window-related features
 *
 * This class coordinates all window modifications including:
 * - Window borders and outlines
 * - Window shadows
 * - Window transparency
 * - Window blur effects
 * - Titlebar modifications
 * - Traffic light customization
 * - Size constraints
 */
@interface WindowManager : NSObject

// Initialization
- (instancetype)initWithConfigManager:(ConfigManager *)configManager;

// Lifecycle management
- (void)start;
- (void)stop;
- (void)reloadConfiguration;

// Feature control
- (void)enableFeature:(NSString *)featureName;
- (void)disableFeature:(NSString *)featureName;
- (BOOL)isFeatureEnabled:(NSString *)featureName;

// Window management
- (void)updateWindow:(NSWindow *)window;
- (void)updateAllWindows;
- (void)handleWindowUpdate:(NSNotification *)notification;

// Feature-specific methods
- (void)applyBorderToWindow:(NSWindow *)window;
- (void)applyShadowToWindow:(NSWindow *)window;
- (void)applyTransparencyToWindow:(NSWindow *)window;
- (void)applyBlurToWindow:(NSWindow *)window;
- (void)modifyTitlebarForWindow:(NSWindow *)window;
- (void)modifyTrafficLightsForWindow:(NSWindow *)window;

// Configuration access
- (NSDictionary *)getWindowConfiguration;
- (id)getWindowValueForKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
