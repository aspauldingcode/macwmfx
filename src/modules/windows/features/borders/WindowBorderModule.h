//
//  WindowBorderModule.h
//  macwmfx
//
//  Created by Alex "aspauldingcode" on 01/09/25.
//  Copyright (c) 2025 Alex "aspauldingcode". All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "main/module_loader.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Window Border Module
 *
 * Handles window border customization including:
 * - Border width and corner radius
 * - Custom colors for active/inactive/stacked states
 * - Border type (inline, outline, etc.)
 */
@interface WindowBorderModule : NSObject <macwmfxModule>

// Configuration properties
@property (nonatomic, assign) BOOL enabled;
@property (nonatomic, assign) float width;
@property (nonatomic, assign) float cornerRadius;
@property (nonatomic, strong, nullable) NSColor *customColor;

// Border type
@property (nonatomic, assign) NSInteger borderType; // 0 = inline, 1 = outline

// Singleton access
+ (instancetype)sharedInstance;

// Window management
- (void)updateWindow:(NSWindow *)window;
- (void)updateAllWindows;

// Configuration
- (void)loadConfiguration;
- (void)saveConfiguration;

@end

NS_ASSUME_NONNULL_END
