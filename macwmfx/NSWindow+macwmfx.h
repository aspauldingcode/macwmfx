//
//  NSWindow+macwmfx.h
//  macwmfx
//
//  Created by Alex "aspauldingcode" on 11/13/24.
//  Copyright (c) 2024 Alex "aspauldingcode". All rights reserved.
//

#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSWindow (macwmfx)

+ (NSWindow *)topWindow;
- (void)setCGWindowLevel:(CGWindowLevel)level;
- (BOOL)isSystemApp;
- (void)hideTrafficLights;
- (void)modifyTitlebarAppearance;
- (void)makeResizableToAnySize;

@end

@interface BordersController : NSObject

@property (strong, nonatomic, readonly) NSColor *activeWindowColor;
@property (strong, nonatomic, readonly) NSColor *inactiveWindowColor;

- (void)addBorderToWindow:(NSWindow *)window;
- (void)removeBorderFromWindow:(NSWindow *)window;
- (void)updateBorderForWindow:(NSWindow *)window;

@end

@interface macwmfx : NSObject

+ (instancetype)sharedInstance;

@property (strong, nonatomic, readonly) BordersController *bordersController;

@end

NS_ASSUME_NONNULL_END
