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
    NSString *configPath = [NSHomeDirectory() stringByAppendingPathComponent:@".config/macwmfx/config"];
    NSLog(@"Attempting to load config from: %@", configPath);
    
    NSData *data = [NSData dataWithContentsOfFile:configPath];
    if (data) {
        NSError *error = nil;
        NSDictionary *config = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        if (!error && config != nil) {
            // Load values from config
            if (config[@"blurPasses"]) {
                gBlurPasses = [config[@"blurPasses"] integerValue];
                NSLog(@"Set gBlurPasses to: %ld", (long)gBlurPasses);
            }
            if (config[@"blurRadius"]) {
                gBlurRadius = [config[@"blurRadius"] doubleValue];
                NSLog(@"Set gBlurRadius to: %f", gBlurRadius);
            }
            if (config[@"transparency"]) {
                gTransparency = [config[@"transparency"] doubleValue];
                NSLog(@"Set gTransparency to: %f", gTransparency);
            }
            
            // Window behavior
            if (config[@"disableTitlebar"]) {
                gDisableTitlebar = [config[@"disableTitlebar"] boolValue];
                NSLog(@"Set gDisableTitlebar to: %d", gDisableTitlebar);
            }
            if (config[@"disableTrafficLights"]) {
                gDisableTrafficLights = [config[@"disableTrafficLights"] boolValue];
                NSLog(@"Set gDisableTrafficLights to: %d", gDisableTrafficLights);
            }
            if (config[@"disableWindowSizeConstraints"]) {
                gDisableWindowSizeConstraints = [config[@"disableWindowSizeConstraints"] boolValue];
                NSLog(@"Set gDisableWindowSizeConstraints to: %d", gDisableWindowSizeConstraints);
            }
            
            // Window outline
            NSDictionary *outlineConfig = config[@"outlineWindow"];
            if (outlineConfig) {
                if (outlineConfig[@"enabled"]) {
                    gOutlineEnabled = [outlineConfig[@"enabled"] boolValue];
                    NSLog(@"Set gOutlineEnabled to: %d", gOutlineEnabled);
                }
                if (outlineConfig[@"width"]) {
                    gOutlineWidth = [outlineConfig[@"width"] doubleValue];
                    NSLog(@"Set gOutlineWidth to: %f", gOutlineWidth);
                }
                if (outlineConfig[@"cornerRadius"]) {
                    gOutlineCornerRadius = [outlineConfig[@"cornerRadius"] doubleValue];
                    NSLog(@"Set gOutlineCornerRadius to: %f", gOutlineCornerRadius);
                }
                if (outlineConfig[@"type"]) {
                    gOutlineType = [outlineConfig[@"type"] copy];
                    NSLog(@"Set gOutlineType to: %@", gOutlineType);
                }
                if (outlineConfig[@"activeColor"]) {
                    gOutlineActiveColor = [self colorFromHexString:outlineConfig[@"activeColor"]];
                    NSLog(@"Set gOutlineActiveColor from hex: %@", outlineConfig[@"activeColor"]);
                }
                if (outlineConfig[@"inactiveColor"]) {
                    gOutlineInactiveColor = [self colorFromHexString:outlineConfig[@"inactiveColor"]];
                    NSLog(@"Set gOutlineInactiveColor from hex: %@", outlineConfig[@"inactiveColor"]);
                }
            }
            
            // System appearance
            if (config[@"systemColorSchemeVariant"]) {
                gSystemColorSchemeVariant = [config[@"systemColorSchemeVariant"] copy];
                NSLog(@"Set gSystemColorSchemeVariant to: %@", gSystemColorSchemeVariant);
            }
            
            NSLog(@"Config loaded successfully");
        } else {
            NSLog(@"Error reading config: %@", error);
        }
    } else {
        NSLog(@"Config file not found at path: %@", configPath);
    }
}

@end
