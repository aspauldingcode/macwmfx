#import <AppKit/AppKit.h>
#import "WindowBorders.h"

static void *BorderWindowKey = &BorderWindowKey;
static const CGFloat kBorderWidth = 2.0;

@implementation NSWindow (WindowBorders)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self swizzleMethod:@selector(becomeKeyWindow) withMethod:@selector(wmfx_becomeKeyWindow)];
        [self swizzleMethod:@selector(resignKeyWindow) withMethod:@selector(wmfx_resignKeyWindow)];
        [self swizzleMethod:@selector(setFrame:display:) withMethod:@selector(wmfx_setFrame:display:)];
        [self swizzleMethod:@selector(setFrame:display:animate:) withMethod:@selector(wmfx_setFrame:display:animate:)];
        [self swizzleMethod:@selector(orderWindow:relativeTo:) withMethod:@selector(wmfx_orderWindow:relativeTo:)];
        [self swizzleMethod:@selector(setLevel:) withMethod:@selector(wmfx_setLevel:)];
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

- (void)wmfx_becomeKeyWindow {
    [self wmfx_becomeKeyWindow];
    [self updateBorderWindow:YES];
}

- (void)wmfx_resignKeyWindow {
    [self wmfx_resignKeyWindow];
    [self updateBorderWindow:NO];
}

- (void)wmfx_setFrame:(NSRect)frame display:(BOOL)display {
    [self wmfx_setFrame:frame display:display];
    [self updateBorderWindowFrame];
}

- (void)wmfx_setFrame:(NSRect)frame display:(BOOL)display animate:(BOOL)animate {
    [self wmfx_setFrame:frame display:display animate:animate];
    [self updateBorderWindowFrame];
}

- (void)wmfx_orderWindow:(NSWindowOrderingMode)orderingMode relativeTo:(NSInteger)otherWindowNumber {
    [self wmfx_orderWindow:orderingMode relativeTo:otherWindowNumber];
    
    NSWindow *borderWindow = objc_getAssociatedObject(self, BorderWindowKey);
    if (borderWindow) {
        [borderWindow orderWindow:orderingMode relativeTo:self.windowNumber];
    }
}

- (void)wmfx_setLevel:(NSInteger)windowLevel {
    [self wmfx_setLevel:windowLevel];
    
    NSWindow *borderWindow = objc_getAssociatedObject(self, BorderWindowKey);
    if (borderWindow) {
        [borderWindow setLevel:windowLevel];
    }
}

- (void)updateBorderWindow:(BOOL)isActive {
    NSWindow *borderWindow = objc_getAssociatedObject(self, BorderWindowKey);
    if (!borderWindow) {
        NSRect frame = self.frame;
        borderWindow = [[NSWindow alloc] initWithContentRect:frame
                                                 styleMask:NSWindowStyleMaskBorderless
                                                   backing:NSBackingStoreBuffered
                                                     defer:NO];
        
        [borderWindow setBackgroundColor:[NSColor clearColor]];
        [borderWindow setOpaque:NO];
        [borderWindow setHasShadow:NO];
        [borderWindow setLevel:self.level];
        [borderWindow setIgnoresMouseEvents:YES];
        [borderWindow setCollectionBehavior:self.collectionBehavior];
        
        // Create a view for the border
        NSView *borderView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, frame.size.width, frame.size.height)];
        borderView.wantsLayer = YES;
        borderView.layer.borderWidth = kBorderWidth;
        borderWindow.contentView = borderView;
        
        objc_setAssociatedObject(self, BorderWindowKey, borderWindow, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    NSView *borderView = borderWindow.contentView;
    borderView.layer.borderColor = isActive ? NSColor.controlAccentColor.CGColor : NSColor.selectedControlColor.CGColor;
    
    [self updateBorderWindowFrame];
    [borderWindow orderWindow:NSWindowAbove relativeTo:self.windowNumber];
}

- (void)updateBorderWindowFrame {
    NSWindow *borderWindow = objc_getAssociatedObject(self, BorderWindowKey);
    if (!borderWindow) return;
    
    NSRect frame = self.frame;
    NSRect borderFrame = NSInsetRect(frame, -kBorderWidth, -kBorderWidth);
    
    [borderWindow setFrame:borderFrame display:YES];
    
    // Update the content view's frame
    NSView *borderView = borderWindow.contentView;
    borderView.frame = NSMakeRect(0, 0, borderFrame.size.width, borderFrame.size.height);
}

@end
