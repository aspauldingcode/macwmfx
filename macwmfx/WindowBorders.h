#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <objc/runtime.h>

@interface NSWindow (WindowBorders)

- (void)updateBorderWindow:(BOOL)isActive;
- (void)updateBorderWindowFrame;

@end 