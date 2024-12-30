#import <AppKit/AppKit.h>
#import <CoreImage/CoreImage.h>
#import "ZKSwizzle.h"
#import "macwmfx_globals.h"
#import <objc/runtime.h>

@interface BlurController : NSObject
+ (instancetype)sharedInstance;
@end

@implementation BlurController

+ (void)load {
    // Initialize the swizzle when the class is loaded
    [self sharedInstance];
}

+ (instancetype)sharedInstance {
    static BlurController *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

@end

ZKSwizzleInterface(BS_NSWindow_Blur, NSWindow, NSWindow)

@implementation BS_NSWindow_Blur

- (void)makeKeyAndOrderFront:(id)sender {
    ZKOrig(void, sender);
    [self applyBlurEffect];
}

- (void)applyBlurEffect {
    NSWindow *window = (NSWindow *)self;
    NSView *contentView = window.contentView;
    
    // Only proceed if we have valid blur settings
    if (gBlurPasses <= 0 || gBlurRadius <= 0) return;
    
    // Create visual effect view if needed
    NSVisualEffectView *blurView = objc_getAssociatedObject(window, "blurView");
    if (!blurView) {
        blurView = [[NSVisualEffectView alloc] initWithFrame:contentView.bounds];
        blurView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
        blurView.blendingMode = NSVisualEffectBlendingModeBehindWindow;
        blurView.material = NSVisualEffectMaterialWindowBackground;
        blurView.state = NSVisualEffectStateActive;
        
        // Store the blur view
        objc_setAssociatedObject(window, "blurView", blurView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
        // Insert blur view behind content
        [contentView addSubview:blurView positioned:NSWindowBelow relativeTo:nil];
    }
    
    // Make sure the window can show the blur
    window.opaque = NO;
    window.backgroundColor = [NSColor clearColor];
    
    // Apply additional blur if needed
    if (gBlurPasses > 1) {
        NSMutableArray *filters = [NSMutableArray array];
        for (NSInteger i = 0; i < gBlurPasses; i++) {
            CIFilter *blur = [CIFilter filterWithName:@"CIGaussianBlur"];
            [blur setValue:@(gBlurRadius) forKey:@"inputRadius"];
            [filters addObject:blur];
        }
        blurView.layer.backgroundFilters = filters;
    }
}

@end