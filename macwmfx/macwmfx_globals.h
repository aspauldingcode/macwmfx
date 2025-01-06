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
extern BOOL gIsEnabled;
extern NSInteger gBlurPasses;
extern CGFloat gBlurRadius;
extern CGFloat gTransparency;
extern BOOL gDisableWindowShadow;

// Window Behavior
extern BOOL gDisableTitlebar;
extern BOOL gDisableTrafficLights;
extern BOOL gDisableWindowSizeConstraints;

// Window Outline
extern BOOL gOutlineEnabled;
extern CGFloat gOutlineWidth;
extern CGFloat gOutlineCornerRadius;
extern NSString *gOutlineType;
extern NSColor *gOutlineActiveColor;
extern NSColor *gOutlineInactiveColor;

// System Appearance
extern NSString *gSystemColorSchemeVariant;

// Flag to indicate if we're running from CLI
extern BOOL gRunningFromCLI;

#ifdef __cplusplus
}
#endif

#endif /* MACWMFX_GLOBALS_H */
