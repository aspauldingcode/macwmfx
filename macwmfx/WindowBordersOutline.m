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
- (void)wmfx_windowDidMove:(NSNotification *)notification;
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

- (void)wmfx_orderFront:(id)sender {
    [self wmfx_orderFront:sender];
    NSWindow *borderWindow = objc_getAssociatedObject(self, BorderWindowKey);
    if (borderWindow) {
        [borderWindow orderWindow:NSWindowAbove relativeTo:self.windowNumber];
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
        // Create border window larger than the parent window
        NSRect parentFrame = self.frame;
        NSRect borderFrame = NSInsetRect(parentFrame, -kBorderWidth, -kBorderWidth);
        
        borderWindow = [[NSWindow alloc] initWithContentRect:borderFrame
                                                 styleMask:NSWindowStyleMaskBorderless
                                                   backing:NSBackingStoreBuffered
                                                     defer:NO];
        
        [borderWindow setBackgroundColor:[NSColor clearColor]];
        [borderWindow setOpaque:NO];
        [borderWindow setHasShadow:NO];
        [borderWindow setLevel:self.level];
        [borderWindow setIgnoresMouseEvents:YES];
        [borderWindow setParentWindow:self];
        [borderWindow setCollectionBehavior:self.collectionBehavior];
        [borderWindow setReleasedWhenClosed:NO];
        [borderWindow setAnimationBehavior:NSWindowAnimationBehaviorNone];
        
        // Create a view that fills the entire border window
        NSView *borderView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, borderFrame.size.width, borderFrame.size.height)];
        borderView.wantsLayer = YES;
        borderView.layer.borderWidth = kBorderWidth;
        borderWindow.contentView = borderView;
        
        // Add window movement notification observer
        [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(wmfx_windowDidMove:)
                                                 name:NSWindowDidMoveNotification
                                               object:self];
        
        objc_setAssociatedObject(self, BorderWindowKey, borderWindow, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    NSView *borderView = borderWindow.contentView;
    borderView.layer.borderColor = isActive ? NSColor.controlAccentColor.CGColor : NSColor.selectedControlColor.CGColor;
    
    if (self.isVisible) {
        [self updateBorderWindowFrame];
        [borderWindow setIsVisible:YES];
        [borderWindow orderWindow:NSWindowAbove relativeTo:self.windowNumber];
    }
}

- (void)wmfx_windowDidMove:(NSNotification *)notification {
    [self updateBorderWindowFrame];
}

- (void)updateBorderWindowFrame {
    NSWindow *borderWindow = objc_getAssociatedObject(self, BorderWindowKey);
    if (!borderWindow) return;
    
    // Make border window larger than parent window
    NSRect parentFrame = self.frame;
    NSRect borderFrame = NSInsetRect(parentFrame, -kBorderWidth, -kBorderWidth);
    
    [borderWindow setFrame:borderFrame display:NO];
    [borderWindow orderWindow:NSWindowAbove relativeTo:self.windowNumber];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end