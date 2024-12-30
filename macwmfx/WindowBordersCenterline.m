#import <AppKit/AppKit.h>
#import <objc/runtime.h>
#import "macwmfx_globals.h"

static void *BorderLayerKey = &BorderLayerKey;

@interface NSWindow (WindowBorders)
- (void)updateBorderLayer:(BOOL)isActive;
@end

@implementation NSWindow (WindowBorders)

+ (void)load {
    // Only proceed if borders are enabled and type is "centerline"
    if (!gOutlineEnabled || ![gOutlineType isEqualToString:@"centerline"]) return;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self swizzleMethod:@selector(becomeKeyWindow) withMethod:@selector(wmfx_becomeKeyWindow)];
        [self swizzleMethod:@selector(resignKeyWindow) withMethod:@selector(wmfx_resignKeyWindow)];
        [self swizzleMethod:@selector(makeKeyWindow) withMethod:@selector(wmfx_makeKeyWindow)];
        [self swizzleMethod:@selector(initWithContentRect:styleMask:backing:defer:) 
                withMethod:@selector(wmfx_initWithContentRect:styleMask:backing:defer:)];
    });
}

+ (void)swizzleMethod:(SEL)original withMethod:(SEL)swizzled {
    Class class = self;
    Method originalMethod = class_getInstanceMethod(class, original);
    Method swizzledMethod = class_getInstanceMethod(class, swizzled);
    
    BOOL didAdd = class_addMethod(class, original,
                                method_getImplementation(swizzledMethod),
                                method_getTypeEncoding(swizzledMethod));
    
    if (didAdd) {
        class_replaceMethod(class, swizzled,
                          method_getImplementation(originalMethod),
                          method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

- (instancetype)wmfx_initWithContentRect:(NSRect)contentRect
                              styleMask:(NSWindowStyleMask)style
                                backing:(NSBackingStoreType)backingStoreType
                                  defer:(BOOL)flag {
    NSWindow *window = [self wmfx_initWithContentRect:contentRect
                                           styleMask:style
                                             backing:backingStoreType
                                               defer:flag];
    [window updateBorderLayer:NO];
    return window;
}

- (void)wmfx_makeKeyWindow {
    [self wmfx_makeKeyWindow];
    [self updateBorderLayer:YES];
}

- (void)wmfx_becomeKeyWindow {
    [self wmfx_becomeKeyWindow];
    [self updateBorderLayer:YES];
}

- (void)wmfx_resignKeyWindow {
    [self wmfx_resignKeyWindow];
    [self updateBorderLayer:NO];
}

- (void)updateBorderLayer:(BOOL)isActive {
    // Only proceed if borders are enabled and type is "centerline"
    if (!gOutlineEnabled || ![gOutlineType isEqualToString:@"centerline"]) return;
    
    NSView *frameView = [self.contentView superview];
    if (!frameView) return;
    
    frameView.wantsLayer = YES;
    
    CALayer *borderLayer = objc_getAssociatedObject(self, BorderLayerKey);
    if (!borderLayer) {
        borderLayer = [CALayer layer];
        borderLayer.frame = frameView.bounds;
        borderLayer.borderWidth = gOutlineWidth;
        borderLayer.cornerRadius = gOutlineCornerRadius;
        borderLayer.masksToBounds = NO;
        borderLayer.backgroundColor = NSColor.clearColor.CGColor;
        
        frameView.layer = borderLayer;
        objc_setAssociatedObject(self, BorderLayerKey, borderLayer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    borderLayer.borderColor = isActive ? 
        (gOutlineActiveColor ? gOutlineActiveColor.CGColor : NSColor.controlAccentColor.CGColor) : 
        (gOutlineInactiveColor ? gOutlineInactiveColor.CGColor : NSColor.selectedControlColor.CGColor);
    [frameView setNeedsDisplay:YES];
}

@end