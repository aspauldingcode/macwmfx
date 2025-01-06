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

// Window Appearance
__attribute__((visibility("default"))) extern BOOL gIsEnabled;
__attribute__((visibility("default"))) extern NSInteger gBlurPasses;
__attribute__((visibility("default"))) extern CGFloat gBlurRadius;
__attribute__((visibility("default"))) extern CGFloat gTransparency;

// Window Behavior
__attribute__((visibility("default"))) extern BOOL gDisableTitlebar;
__attribute__((visibility("default"))) extern BOOL gDisableTrafficLights;
__attribute__((visibility("default"))) extern BOOL gDisableWindowSizeConstraints;

// Window Outline
__attribute__((visibility("default"))) extern BOOL gOutlineEnabled;
__attribute__((visibility("default"))) extern CGFloat gOutlineWidth;
__attribute__((visibility("default"))) extern CGFloat gOutlineCornerRadius;
__attribute__((visibility("default"))) extern NSString *gOutlineType;
__attribute__((visibility("default"))) extern NSColor *gOutlineActiveColor;
__attribute__((visibility("default"))) extern NSColor *gOutlineInactiveColor;

// System Appearance
__attribute__((visibility("default"))) extern NSString *gSystemColorSchemeVariant;

// Window Shadow
__attribute__((visibility("default"))) extern BOOL gDisableWindowShadow;

// Flag to indicate if we're running from CLI
extern BOOL gRunningFromCLI;

#ifdef __cplusplus
}
#endif

#endif /* MACWMFX_GLOBALS_H */
