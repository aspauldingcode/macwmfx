//
//  configParser.m
//  macwmfx
//
//  Created by Alex "aspauldingcode" on 01/09/25.
//  Copyright (c) 2025 Alex "aspauldingcode". All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "../headers/macwmfx_globals.h"

@implementation ConfigParser

+ (instancetype)sharedInstance {
    static ConfigParser *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[ConfigParser alloc] init];
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

- (void)loadConfig {
    NSString *appSupportPath = @"/Library/Application Support/macwmfx";
    NSString *configPath = [appSupportPath stringByAppendingPathComponent:@"config.json"];
    NSData *configData = [NSData dataWithContentsOfFile:configPath];
    
    if (!configData) {
        NSLog(@"[macwmfx] No config found at %@", configPath);
        return;
    }
    
    NSError *error = nil;
    NSDictionary *config = [NSJSONSerialization JSONObjectWithData:configData options:0 error:&error];
    
    if (error || !config) {
        NSLog(@"[macwmfx] Error parsing config file: %@", error);
        return;
    }
    
    // Parse Window Configuration
    NSDictionary *windowConfig = config[@"window"];
    if (windowConfig) {
        // Window Blur
        NSDictionary *blurConfig = windowConfig[@"blur"];
        if (blurConfig) {
            gBlurConfig.enabled = [blurConfig[@"enabled"] boolValue];
            gBlurConfig.passes = [blurConfig[@"passes"] integerValue] ?: gBlurConfig.passes;
            gBlurConfig.radius = [blurConfig[@"radius"] doubleValue] ?: gBlurConfig.radius;
        }
        
        // Window Titlebar
        NSDictionary *titlebarConfig = windowConfig[@"titlebar"];
        if (titlebarConfig) {
            gTitlebarConfig.enabled = [titlebarConfig[@"enabled"] boolValue];
            gTitlebarConfig.forceClassic = [titlebarConfig[@"forceClassic"] boolValue];
            
            // Parse aesthetics
            NSDictionary *aestheticsConfig = titlebarConfig[@"aesthetics"];
            if (aestheticsConfig) {
                gTitlebarConfig.aesthetics.enabled = [aestheticsConfig[@"enabled"] boolValue];
                gTitlebarConfig.aesthetics.activeColor = [self colorFromHexString:aestheticsConfig[@"activeColor"]];
                gTitlebarConfig.aesthetics.inactiveColor = [self colorFromHexString:aestheticsConfig[@"inactiveColor"]];
            }
            
            if (titlebarConfig[@"color"]) {
                gTitlebarConfig.backgroundColor = [self colorFromHexString:titlebarConfig[@"color"][@"background"]];
                gTitlebarConfig.foregroundColor = [self colorFromHexString:titlebarConfig[@"color"][@"foreground"]];
            }
            gTitlebarConfig.style = [titlebarConfig[@"style"] copy] ?: @"modern";
            gTitlebarConfig.size = [titlebarConfig[@"size"] doubleValue] ?: 22.0;
            
            // Custom Title
            NSDictionary *customTitleConfig = titlebarConfig[@"customTitle"];
            if (customTitleConfig) {
                gCustomTitleConfig.enabled = [customTitleConfig[@"enabled"] boolValue];
                if (customTitleConfig[@"title"]) {
                    NSString *title = customTitleConfig[@"title"];
                    gCustomTitleConfig.title = [title UTF8String];
                }
            }
        }
        
        // Window Traffic Lights
        NSDictionary *trafficLightsConfig = windowConfig[@"trafficLights"];
        if (trafficLightsConfig) {
            gTrafficLightsConfig.enabled = [trafficLightsConfig[@"enabled"] boolValue];
            NSLog(@"[macwmfx] Traffic lights enabled: %d", gTrafficLightsConfig.enabled);
            if (trafficLightsConfig[@"color"]) {
                gTrafficLightsConfig.stopColor = [self colorFromHexString:trafficLightsConfig[@"color"][@"stop"]];
                gTrafficLightsConfig.yieldColor = [self colorFromHexString:trafficLightsConfig[@"color"][@"yield"]];
                gTrafficLightsConfig.goColor = [self colorFromHexString:trafficLightsConfig[@"color"][@"go"]];
            }
            gTrafficLightsConfig.style = [trafficLightsConfig[@"style"] copy] ?: @"macOS";
            gTrafficLightsConfig.size = [trafficLightsConfig[@"size"] doubleValue] ?: 12.0;
            gTrafficLightsConfig.position = [trafficLightsConfig[@"position"] copy] ?: @"top-left";
        }
        
        // Window Shadow
        NSDictionary *shadowConfig = windowConfig[@"shadow"];
        if (shadowConfig) {
            gShadowConfig.enabled = [shadowConfig[@"enabled"] boolValue];
            gShadowConfig.color = [self colorFromHexString:shadowConfig[@"color"]];
        }
        
        // Window Size Constraints
        NSDictionary *sizeConstraintsConfig = windowConfig[@"sizeConstraints"];
        if (sizeConstraintsConfig) {
            gWindowSizeConstraintsConfig.enabled = [sizeConstraintsConfig[@"enabled"] boolValue];
        }
        
        // Window Outline
        NSDictionary *outlineConfig = windowConfig[@"outline"];
        if (outlineConfig) {
            gOutlineConfig.enabled = [outlineConfig[@"enabled"] boolValue];
            if (outlineConfig[@"color"]) {
                gOutlineConfig.activeColor = [self colorFromHexString:outlineConfig[@"color"][@"active"]];
                gOutlineConfig.inactiveColor = [self colorFromHexString:outlineConfig[@"color"][@"inactive"]];
                gOutlineConfig.stackedColor = [self colorFromHexString:outlineConfig[@"color"][@"stacked"]];
            }
            gOutlineConfig.cornerRadius = [outlineConfig[@"cornerRadius"] doubleValue] ?: 40.0;
            gOutlineConfig.type = [outlineConfig[@"type"] copy] ?: @"inline";
            gOutlineConfig.width = [outlineConfig[@"width"] doubleValue] ?: 2.0;
        }
        
        // Window Transparency
        NSDictionary *transparencyConfig = windowConfig[@"transparency"];
        if (transparencyConfig) {
            gTransparencyConfig.enabled = [transparencyConfig[@"enabled"] boolValue];
            gTransparencyConfig.value = [transparencyConfig[@"value"] doubleValue] ?: 0.5;
        }
    }
    
    // System Color Scheme
    NSDictionary *systemColorConfig = config[@"systemColorScheme"];
    if (systemColorConfig) {
        gSystemColorConfig.variant = [systemColorConfig[@"variant"] copy] ?: @"dark";
        gSystemColorConfig.slug = [systemColorConfig[@"slug"] copy] ?: @"gruvbox-dark-soft";
        if (systemColorConfig[@"colors"]) {
            [self parseColorScheme:systemColorConfig[@"colors"]];
        }
    }
    
    NSLog(@"[macwmfx] Config loaded from %@", configPath);
}

- (void)parseColorScheme:(NSDictionary *)colors {
    gSystemColorConfig.colors.base00 = [self colorFromHexString:colors[@"base00"]];
    gSystemColorConfig.colors.base01 = [self colorFromHexString:colors[@"base01"]];
    gSystemColorConfig.colors.base02 = [self colorFromHexString:colors[@"base02"]];
    gSystemColorConfig.colors.base03 = [self colorFromHexString:colors[@"base03"]];
    gSystemColorConfig.colors.base04 = [self colorFromHexString:colors[@"base04"]];
    gSystemColorConfig.colors.base05 = [self colorFromHexString:colors[@"base05"]];
    gSystemColorConfig.colors.base06 = [self colorFromHexString:colors[@"base06"]];
    gSystemColorConfig.colors.base07 = [self colorFromHexString:colors[@"base07"]];
    gSystemColorConfig.colors.base08 = [self colorFromHexString:colors[@"base08"]];
    gSystemColorConfig.colors.base09 = [self colorFromHexString:colors[@"base09"]];
    gSystemColorConfig.colors.base0A = [self colorFromHexString:colors[@"base0A"]];
    gSystemColorConfig.colors.base0B = [self colorFromHexString:colors[@"base0B"]];
    gSystemColorConfig.colors.base0C = [self colorFromHexString:colors[@"base0C"]];
    gSystemColorConfig.colors.base0D = [self colorFromHexString:colors[@"base0D"]];
    gSystemColorConfig.colors.base0E = [self colorFromHexString:colors[@"base0E"]];
    gSystemColorConfig.colors.base0F = [self colorFromHexString:colors[@"base0F"]];
}

@end
