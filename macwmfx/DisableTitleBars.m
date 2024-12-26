#import <Cocoa/Cocoa.h>
#import "ZKSwizzle.h"

@interface DisableTitleBars : NSObject
@end

@implementation DisableTitleBars

+ (void)load {
    // Initialize the swizzle when the class is loaded
    [self sharedInstance];
}

+ (instancetype)sharedInstance {
    static DisableTitleBars *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

@end

ZKSwizzleInterface(BS_NSWindow_TitleBar, NSWindow, NSWindow)

@implementation BS_NSWindow_TitleBar

- (void)makeKeyAndOrderFront:(id)sender {
    ZKOrig(void, sender);
    
    // Disable the title bar
    // [self disableTitleBar]; // TODO: Add this back in after bugfixes.
}

- (void)disableTitleBar {
    NSWindow *window = (NSWindow *)self;
    window.titlebarAppearsTransparent = YES;
    window.titleVisibility = NSWindowTitleHidden;
    window.styleMask |= NSWindowStyleMaskFullSizeContentView;
    window.contentView.wantsLayer = YES; // Ensure contentView is layer-backed
}

@end 