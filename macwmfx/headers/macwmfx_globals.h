//
//  macwmfx_globals.h
// macwmfx
//
//  Created by Alex "aspauldingcode" on 11/13/24.
//  Copyright (c) 2024 Alex "aspauldingcode". All rights reserved.
//
#ifndef MACWMFX_GLOBALS_H
#define MACWMFX_GLOBALS_H

#import <AppKit/AppKit.h>
#import "ZKSwizzle.h"
#import <Cocoa/Cocoa.h>

#ifdef __cplusplus
extern "C" {
#endif

// Shared memory structure for IPC
typedef struct {
    BOOL outlineEnabled;
    CGFloat outlineWidth;
    CGFloat outlineCornerRadius;
    BOOL updateNeeded;
} SharedMemory;

// Path for shared memory
#define SHARED_MEMORY_PATH "/tmp/macwmfx_shared"

// Function to get shared memory
SharedMemory* getSharedMemory(void);

// Configuration Structures
typedef struct {
    BOOL enabled;
    NSInteger passes;
    CGFloat radius;
} BlurConfig;

typedef struct {
    BOOL enabled;
    NSColor *activeColor;
    NSColor *inactiveColor;
} TitlebarAesthetics;

typedef struct {
    BOOL enabled;
    NSColor *activeBackground;    // For active window
    NSColor *activeForeground;    // For active window
    NSColor *inactiveBackground;  // For inactive window
    NSColor *inactiveForeground;  // For inactive window
} TitlebarCustomColor;

typedef struct {
    BOOL enabled;
    BOOL forceClassic;
    TitlebarAesthetics aesthetics;
    NSString *style;
    CGFloat size;
    TitlebarCustomColor customColor;
} TitlebarConfig;

typedef struct {
    BOOL enabled;
    const char *title;
} CustomTitleConfig;

// Traffic Lights Color State Config
typedef struct {
    NSString *stop;
    NSString *yield;
    NSString *go;
} TrafficLightsColorState;

// Traffic Lights Custom Color Config
typedef struct {
    BOOL enabled;
    TrafficLightsColorState active;
    TrafficLightsColorState inactive;
    TrafficLightsColorState hover;
} TrafficLightsColorConfig;

// Traffic Lights Config
typedef struct {
    BOOL enabled;
    NSString *style;
    NSString *shape;
    NSString *order;
    NSString *position;
    CGFloat size;
    CGFloat padding;
    TrafficLightsColorConfig customColor;
} TrafficLightsConfig;

typedef struct {
    BOOL enabled;
    struct {
        BOOL enabled;
        NSString *active;
        NSString *inactive;
    } customColor;
} ShadowConfig;

typedef struct {
    BOOL enabled;
} WindowSizeConstraintsConfig;

typedef struct {
    BOOL enabled;
    NSString *type;
    CGFloat width;
    CGFloat cornerRadius;
    struct {
        BOOL enabled;
        NSColor *active;
        NSColor *inactive;
        NSColor *stacked;
    } customColor;
} OutlineConfig;

typedef struct {
    BOOL enabled;
    CGFloat value;
} TransparencyConfig;

typedef struct {
    NSColor *base00;
    NSColor *base01;
    NSColor *base02;
    NSColor *base03;
    NSColor *base04;
    NSColor *base05;
    NSColor *base06;
    NSColor *base07;
    NSColor *base08;
    NSColor *base09;
    NSColor *base0A;
    NSColor *base0B;
    NSColor *base0C;
    NSColor *base0D;
    NSColor *base0E;
    NSColor *base0F;
} SystemColors;

typedef struct {
    NSString *variant;
    NSString *slug;
    SystemColors colors;
} SystemColorConfig;

typedef struct {
    BOOL enabled;
    NSInteger interval;  // Interval in seconds to check for changes
} HotloadConfig;

// Global Configuration Variables
__attribute__((visibility("default"))) extern BOOL gIsEnabled;
__attribute__((visibility("default"))) extern HotloadConfig gHotloadConfig;
__attribute__((visibility("default"))) extern BlurConfig gBlurConfig;
__attribute__((visibility("default"))) extern TitlebarConfig gTitlebarConfig;
__attribute__((visibility("default"))) extern CustomTitleConfig gCustomTitleConfig;
__attribute__((visibility("default"))) extern TrafficLightsConfig gTrafficLightsConfig;
__attribute__((visibility("default"))) extern ShadowConfig gShadowConfig;
__attribute__((visibility("default"))) extern WindowSizeConstraintsConfig gWindowSizeConstraintsConfig;
__attribute__((visibility("default"))) extern OutlineConfig gOutlineConfig;
__attribute__((visibility("default"))) extern TransparencyConfig gTransparencyConfig;
__attribute__((visibility("default"))) extern SystemColorConfig gSystemColorConfig;

// Flag to indicate if we're running from CLI
extern BOOL gRunningFromCLI;

// ConfigParser interface
@interface ConfigParser : NSObject
+ (instancetype)sharedInstance;
- (void)loadConfig;
- (NSColor *)colorFromHexString:(NSString *)hexString;
@end

extern bool WindowDecorations;
extern bool WindowHideShadow;

// Global configuration for menubar height
extern int __height;

#ifdef __cplusplus
}
#endif

#endif /* MACWMFX_GLOBALS_H */
