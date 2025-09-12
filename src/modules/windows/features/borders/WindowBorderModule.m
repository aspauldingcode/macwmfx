#import "WindowBorderModule.h"
#import "macwmfx_globals.h"

@implementation WindowBorderModule

+ (instancetype)sharedInstance {
    static WindowBorderModule *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[WindowBorderModule alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _enabled = NO;
        _width = 1.0f;
        _cornerRadius = 0.0f;
        _customColor = nil;
        _borderType = 0;
    }
    return self;
}

- (BOOL)isEnabled {
    return _enabled;
}

- (void)start {
    if (_enabled) return;
    _enabled = YES;
    [self loadConfiguration];
    [self updateAllWindows];
}

- (void)stop {
    if (!_enabled) return;
    _enabled = NO;
}

- (void)updateWindow:(NSWindow *)window {
    if (!_enabled || !window) return;
    // Minimal window border update implementation
}

- (void)updateAllWindows {
    if (!_enabled) return;
    for (NSWindow *window in [NSApplication sharedApplication].windows) {
        [self updateWindow:window];
    }
}

- (void)loadConfiguration {
    if (gOutlineConfig.enabled) {
        _enabled = YES;
        _width = gOutlineConfig.width;
        _cornerRadius = gOutlineConfig.cornerRadius;
        _customColor = gOutlineConfig.customColor.active;
        _borderType = 0; // Default type
    }
}

- (void)saveConfiguration {
    // Minimal configuration save - update globals
    gOutlineConfig.enabled = _enabled;
    gOutlineConfig.width = _width;
    gOutlineConfig.cornerRadius = _cornerRadius;
    if (_customColor) {
        gOutlineConfig.customColor.active = _customColor;
        gOutlineConfig.customColor.inactive = _customColor;
        gOutlineConfig.customColor.stacked = _customColor;
    }
}

@end
