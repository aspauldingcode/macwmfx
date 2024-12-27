#import <AppKit/AppKit.h>
#import <objc/runtime.h>

static void *BorderWindowKey = &BorderWindowKey;
static const CGFloat kBorderWidth = 2.0;

@interface NSWindow (WindowBordersOutline)
- (void)wmfx_becomeKeyWindow;
- (void)wmfx_resignKeyWindow;
- (void)wmfx_setFrame:(NSRect)frame display:(BOOL)display;
- (void)wmfx_setFrame:(NSRect)frame display:(BOOL)display animate:(BOOL)animate;
- (void)wmfx_orderWindow:(NSWindowOrderingMode)orderingMode relativeTo:(NSInteger)otherWindowNumber;
- (void)wmfx_setLevel:(NSInteger)windowLevel;
- (void)wmfx_orderFront:(id)sender;
- (void)wmfx_orderBack:(id)sender;
- (void)wmfx_orderOut:(id)sender;
- (void)updateBorderWindow:(BOOL)isActive;
- (void)updateBorderWindowFrame;
@end

@implementation NSWindow (WindowBordersOutline)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self swizzleMethod:@selector(becomeKeyWindow) withMethod:@selector(wmfx_becomeKeyWindow)];
        [self swizzleMethod:@selector(resignKeyWindow) withMethod:@selector(wmfx_resignKeyWindow)];
        [self swizzleMethod:@selector(setFrame:display:) withMethod:@selector(wmfx_setFrame:display:)];
        [self swizzleMethod:@selector(setFrame:display:animate:) withMethod:@selector(wmfx_setFrame:display:animate:)];
        [self swizzleMethod:@selector(orderWindow:relativeTo:) withMethod:@selector(wmfx_orderWindow:relativeTo:)];
        [self swizzleMethod:@selector(setLevel:) withMethod:@selector(wmfx_setLevel:)];
        [self swizzleMethod:@selector(orderFront:) withMethod:@selector(wmfx_orderFront:)];
        [self swizzleMethod:@selector(orderBack:) withMethod:@selector(wmfx_orderBack:)];
        [self swizzleMethod:@selector(orderOut:) withMethod:@selector(wmfx_orderOut:)];
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
        [borderWindow orderWindow:orderingMode relativeTo:otherWindowNumber];
    }
}

- (void)wmfx_setLevel:(NSInteger)windowLevel {
    [self wmfx_setLevel:windowLevel];
    NSWindow *borderWindow = objc_getAssociatedObject(self, BorderWindowKey);
    if (borderWindow) {
        [borderWindow setLevel:windowLevel];
    }
}

- (void)wmfx_orderFront:(id)sender {
    [self wmfx_orderFront:sender];
    NSWindow *borderWindow = objc_getAssociatedObject(self, BorderWindowKey);
    if (borderWindow) {
        [borderWindow orderFront:sender];
    }
}

- (void)wmfx_orderBack:(id)sender {
    [self wmfx_orderBack:sender];
    NSWindow *borderWindow = objc_getAssociatedObject(self, BorderWindowKey);
    if (borderWindow) {
        [borderWindow orderWindow:NSWindowBelow relativeTo:self.windowNumber];
    }
}

- (void)wmfx_orderOut:(id)sender {
    NSWindow *borderWindow = objc_getAssociatedObject(self, BorderWindowKey);
    if (borderWindow) {
        [borderWindow orderOut:sender];
    }
    [self wmfx_orderOut:sender];
}

- (void)updateBorderWindow:(BOOL)isActive {
    NSWindow *borderWindow = objc_getAssociatedObject(self, BorderWindowKey);
    
    if (!borderWindow) {
        NSRect frame = NSInsetRect(self.frame, -kBorderWidth, -kBorderWidth);
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
        [borderWindow setParentWindow:self];
        
        NSView *borderView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, frame.size.width, frame.size.height)];
        borderView.wantsLayer = YES;
        borderView.layer.borderWidth = kBorderWidth;
        borderWindow.contentView = borderView;
        
        objc_setAssociatedObject(self, BorderWindowKey, borderWindow, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    NSView *borderView = borderWindow.contentView;
    borderView.layer.borderColor = isActive ? NSColor.controlAccentColor.CGColor : NSColor.selectedControlColor.CGColor;
    
    [self updateBorderWindowFrame];
    if (self.isVisible) {
        [borderWindow setIsVisible:YES];
        [borderWindow orderWindow:NSWindowAbove relativeTo:self.windowNumber];
    }
}

- (void)updateBorderWindowFrame {
    NSWindow *borderWindow = objc_getAssociatedObject(self, BorderWindowKey);
    if (!borderWindow) return;
    
    NSRect frame = self.frame;
    NSRect borderFrame = NSInsetRect(frame, -kBorderWidth, -kBorderWidth);
    [borderWindow setFrame:borderFrame display:YES];
}

@end