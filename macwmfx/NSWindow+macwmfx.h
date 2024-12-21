//
//  NSWindow+macwmfx.h
//  macwmfx
//
//  Created by Alex "aspauldingcode" on 11/13/24.
//  Copyright (c) 2024 Alex "aspauldingcode". All rights reserved.
//

#import <AppKit/AppKit.h>

// Add visibility macros for dylib
#ifdef __cplusplus
#define MACWMFX_EXPORT extern "C" __attribute__((visibility("default")))
#else
#define MACWMFX_EXPORT __attribute__((visibility("default")))
#endif

NS_ASSUME_NONNULL_BEGIN

@interface NSWindow (macwmfx)

MACWMFX_EXPORT NSWindow* topWindow(void);
- (void)setCGWindowLevel:(CGWindowLevel)level;
- (BOOL)isSystemApp;
- (void)hideTrafficLights;
- (void)modifyTitlebarAppearance;
- (void)makeResizableToAnySize;

@end

@interface BordersController : NSObject

@property (strong, nonatomic, readonly) NSColor *activeWindowColor;
@property (strong, nonatomic, readonly) NSColor *inactiveWindowColor;

MACWMFX_EXPORT void addBorderToWindow(NSWindow *window);
MACWMFX_EXPORT void removeBorderFromWindow(NSWindow *window);
MACWMFX_EXPORT void updateBorderForWindow(NSWindow *window);

@end

@interface macwmfx : NSObject

MACWMFX_EXPORT macwmfx* macwmfxSharedInstance(void);

@property (strong, nonatomic, readonly) BordersController *bordersController;

@end

NS_ASSUME_NONNULL_END
