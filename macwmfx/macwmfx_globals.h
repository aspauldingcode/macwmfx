// Create a new header file for globals
#ifndef MACWMFX_GLOBALS_H
#define MACWMFX_GLOBALS_H

#ifdef __OBJC__
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

// Window Appearance
extern BOOL gIsEnabled;
extern NSInteger gBlurPasses;
extern CGFloat gBlurRadius;
extern CGFloat gTransparency;

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

#ifdef __cplusplus
}
#endif

#endif /* MACWMFX_GLOBALS_H */
