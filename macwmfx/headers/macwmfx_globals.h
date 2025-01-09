//
//  macwmfx_globals.h
// macwmfx
//
//  Created by Alex "aspauldingcode" on 11/13/24.
//  Copyright (c) 2024 Alex "aspauldingcode". All rights reserved.
//

// Create a new header file for globals
#ifndef MACWMFX_GLOBALS_H
#define MACWMFX_GLOBALS_H

#ifdef __OBJC__
    #import <AppKit/AppKit.h>
    #import "ZKSwizzle.h"
    #import <Cocoa/Cocoa.h>
#else
    #include <stdbool.h>
   typedef bool BOOL;
    typedef long NSInteger;
    typedef float CGFloat;
    typedef struct NSColor NSColor;
    typedef struct NSString NSString;
    #define nil NULL
#endif

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
    BOOL forceClassic;
    TitlebarAesthetics aesthetics;
    NSColor *backgroundColor;
    NSColor *foregroundColor;
    NSString *style;
    CGFloat size;
} TitlebarConfig;

typedef struct {
    BOOL enabled;
    const char *title;
} CustomTitleConfig;

typedef struct {
    BOOL enabled;
    NSColor *stopColor;
    NSColor *yieldColor;
    NSColor *goColor;
    NSString *style;
    CGFloat size;
    NSString *position;
} TrafficLightsConfig;

typedef struct {
    BOOL enabled;
    NSColor *color;
} ShadowConfig;

typedef struct {
    BOOL enabled;
} WindowSizeConstraintsConfig;

typedef struct {
    BOOL enabled;
    NSColor *activeColor;
    NSColor *inactiveColor;
    NSColor *stackedColor;
    CGFloat cornerRadius;
    NSString *type;
    CGFloat width;
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

// Global Configuration Variables
__attribute__((visibility("default"))) extern BOOL gIsEnabled;
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
@end

#ifdef __cplusplus
}
#endif

#endif /* MACWMFX_GLOBALS_H */
