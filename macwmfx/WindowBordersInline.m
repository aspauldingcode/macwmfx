// #import <AppKit/AppKit.h>
// #import <objc/runtime.h>

// static void *BorderLayerKey = &BorderLayerKey;
// static const CGFloat kBorderWidth = 2.0;

// @interface NSWindow (WindowBordersInline)
// - (void)updateBorderLayer:(BOOL)isActive;
// @end

// @implementation NSWindow (WindowBordersInline)

// + (void)load {
//     static dispatch_once_t onceToken;
//     dispatch_once(&onceToken, ^{
//         [self swizzleMethod:@selector(becomeKeyWindow) withMethod:@selector(wmfx_becomeKeyWindow)];
//         [self swizzleMethod:@selector(resignKeyWindow) withMethod:@selector(wmfx_resignKeyWindow)];
//         [self swizzleMethod:@selector(makeKeyWindow) withMethod:@selector(wmfx_makeKeyWindow)];
//         [self swizzleMethod:@selector(initWithContentRect:styleMask:backing:defer:) 
//                 withMethod:@selector(wmfx_initWithContentRect:styleMask:backing:defer:)];
//     });
// }

// + (void)swizzleMethod:(SEL)original withMethod:(SEL)swizzled {
//     Class class = self;
//     Method originalMethod = class_getInstanceMethod(class, original);
//     Method swizzledMethod = class_getInstanceMethod(class, swizzled);
    
//     BOOL didAdd = class_addMethod(class, original,
//                                 method_getImplementation(swizzledMethod),
//                                 method_getTypeEncoding(swizzledMethod));
    
//     if (didAdd) {
//         class_replaceMethod(class, swizzled,
//                           method_getImplementation(originalMethod),
//                           method_getTypeEncoding(originalMethod));
//     } else {
//         method_exchangeImplementations(originalMethod, swizzledMethod);
//     }
// }

// - (instancetype)wmfx_initWithContentRect:(NSRect)contentRect
//                              styleMask:(NSWindowStyleMask)style
//                                backing:(NSBackingStoreType)backingStoreType
//                                  defer:(BOOL)flag {
//     NSWindow *window = [self wmfx_initWithContentRect:contentRect
//                                           styleMask:style
//                                             backing:backingStoreType
//                                               defer:flag];
//     [window updateBorderLayer:NO];
//     return window;
// }

// - (void)wmfx_makeKeyWindow {
//     [self wmfx_makeKeyWindow];
//     [self updateBorderLayer:YES];
// }

// - (void)wmfx_becomeKeyWindow {
//     [self wmfx_becomeKeyWindow];
//     [self updateBorderLayer:YES];
// }

// - (void)wmfx_resignKeyWindow {
//     [self wmfx_resignKeyWindow];
//     [self updateBorderLayer:NO];
// }

// - (void)updateBorderLayer:(BOOL)isActive {
//     NSView *frameView = [self.contentView superview];
//     if (!frameView) return;
    
//     frameView.wantsLayer = YES;
    
//     CALayer *borderLayer = objc_getAssociatedObject(self, BorderLayerKey);
//     if (!borderLayer) {
//         borderLayer = [CALayer layer];
//         borderLayer.frame = frameView.bounds;
//         borderLayer.borderWidth = kBorderWidth;
//         borderLayer.cornerRadius = 0;
//         borderLayer.masksToBounds = NO;
//         borderLayer.backgroundColor = NSColor.clearColor.CGColor;
        
//         frameView.layer = borderLayer;
//         objc_setAssociatedObject(self, BorderLayerKey, borderLayer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
//     }
    
//     borderLayer.borderColor = isActive ? NSColor.controlAccentColor.CGColor : NSColor.selectedControlColor.CGColor;
//     [frameView setNeedsDisplay:YES];
// }

// @end