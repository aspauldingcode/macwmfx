//
//  macwmfx.m
//  macwmfx
//
//  Created by Alex "aspauldingcode" on 11/13/24.
//  Copyright (c) 2024 Alex "aspauldingcode". All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "macwmfx_globals.h"

// Define the globals with default values
BOOL gIsEnabled = YES;
NSInteger gBlurPasses = 1;
CGFloat gBlurRadius = 10.0;
CGFloat gTransparency = 1.0;

BOOL gDisableTitlebar = NO;
BOOL gDisableTrafficLights = NO;
BOOL gDisableWindowSizeConstraints = NO;

BOOL gOutlineEnabled = YES;
CGFloat gOutlineWidth = 4.0;
CGFloat gOutlineCornerRadius = 10.0;
NSString *gOutlineType = @"inline";
NSColor *gOutlineActiveColor = nil;
NSColor *gOutlineInactiveColor = nil;

NSString *gSystemColorSchemeVariant = @"dark";

BOOL gDisableWindowShadow = NO;  // Default value is NO

@interface MacWMFX : NSObject

+ (instancetype)sharedInstance;
- (void)loadFeaturesFromConfig;
- (void)initializeGlobals;
- (NSColor *)colorFromHexString:(NSString *)hexString;

@end

@implementation MacWMFX

+ (void)load {
    // Initialize the singleton and load config on startup
    MacWMFX *instance = [self sharedInstance];
    [instance loadFeaturesFromConfig];
}

+ (instancetype)sharedInstance {
    static MacWMFX *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[MacWMFX alloc] init];
        [sharedInstance initializeGlobals];
    });
    return sharedInstance;
}

- (NSColor *)colorFromHexString:(NSString *)hexString {
    if (!hexString) return nil;
    
    unsigned int hexInt = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    [scanner scanHexInt:&hexInt];
    
    return [NSColor colorWithRed:((hexInt & 0xFF0000) >> 16) / 255.0
                          green:((hexInt & 0x00FF00) >> 8) / 255.0
                           blue:(hexInt & 0x0000FF) / 255.0
                          alpha:1.0];
}

- (void)initializeGlobals {
    gIsEnabled = YES;
    gBlurPasses = 1;
    gBlurRadius = 10.0;
    gTransparency = 1.0;
    
    gDisableTitlebar = NO;
    gDisableTrafficLights = NO;
    gDisableWindowSizeConstraints = NO;
    
    gOutlineEnabled = YES;
    gOutlineWidth = 4.0;
    gOutlineCornerRadius = 10.0;
    gOutlineType = @"inline";
    gOutlineActiveColor = [NSColor whiteColor];
    gOutlineInactiveColor = [NSColor grayColor];
    
    gSystemColorSchemeVariant = @"dark";
}

- (void)loadFeaturesFromConfig {
    NSString *configPath = [NSString stringWithFormat:@"%@/.config/macwmfx/config", NSHomeDirectory()];
    NSData *configData = [NSData dataWithContentsOfFile:configPath];
    
    if (!configData) {
        NSLog(@"No config found at %@", configPath);
        return;
    }
    
    NSError *error = nil;
    NSDictionary *config = [NSJSONSerialization JSONObjectWithData:configData options:0 error:&error];
    
    if (error || !config) {
        NSLog(@"Error parsing config file: %@", error);
        return;
    }
    
    // Window Appearance
    gBlurPasses = [config[@"blurPasses"] integerValue] ?: gBlurPasses;
    gBlurRadius = [config[@"blurRadius"] doubleValue] ?: gBlurRadius;
    gTransparency = [config[@"transparency"] doubleValue] ?: gTransparency;
    gDisableWindowShadow = [config[@"disableWindowShadow"] boolValue];
    
    // Window Behavior
    gDisableTitlebar = [config[@"disableTitlebar"] boolValue];
    gDisableTrafficLights = [config[@"disableTrafficLights"] boolValue];
    gDisableWindowSizeConstraints = [config[@"disableWindowSizeConstraints"] boolValue];
    
    // Window Outline
    gOutlineEnabled = [config[@"outlineWindow"][@"enabled"] boolValue];
    gOutlineWidth = [config[@"outlineWindow"][@"width"] doubleValue] ?: gOutlineWidth;
    gOutlineCornerRadius = [config[@"outlineWindow"][@"cornerRadius"] doubleValue] ?: gOutlineCornerRadius;
    
    NSString *outlineType = config[@"outlineWindow"][@"type"];
    if (outlineType) {
        gOutlineType = [outlineType copy];
    }
    
    NSString *activeColor = config[@"outlineWindow"][@"activeColor"];
    if (activeColor) {
        gOutlineActiveColor = [self colorFromHexString:activeColor];
    }
    
    NSString *inactiveColor = config[@"outlineWindow"][@"inactiveColor"];
    if (inactiveColor) {
        gOutlineInactiveColor = [self colorFromHexString:inactiveColor];
    }
    
    // System Appearance
    NSString *colorScheme = config[@"systemColorSchemeVariant"];
    if (colorScheme) {
        gSystemColorSchemeVariant = [colorScheme copy];
    }
    
    NSLog(@"Config loaded from JSON file");
}

@end
