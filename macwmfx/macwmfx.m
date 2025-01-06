//
//  macwmfx.m
//  macwmfx
//
//  Created by Alex "aspauldingcode" on 11/13/24.
//  Copyright (c) 2024 Alex "aspauldingcode". All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "macwmfx_globals.h"
#import <sys/mman.h>
#import <fcntl.h>
#import <unistd.h>

// Define the globals with default values
BOOL gIsEnabled = YES;
NSInteger gBlurPasses = 1;
CGFloat gBlurRadius = 10.0;
CGFloat gTransparency = 1.0;

BOOL gDisableTitlebar = NO;
BOOL gDisableTrafficLights = NO;
BOOL gDisableWindowSizeConstraints = NO;

BOOL gOutlineEnabled = YES;
CGFloat gOutlineWidth = 4.0;
CGFloat gOutlineCornerRadius = 10.0;
NSString *gOutlineType = @"inline";
NSColor *gOutlineActiveColor = nil;
NSColor *gOutlineInactiveColor = nil;

NSString *gSystemColorSchemeVariant = @"dark";

BOOL gDisableWindowShadow = NO;  // Default value is NO

// Flag to indicate if we're running from CLI
BOOL gRunningFromCLI = NO;

// Shared memory implementation
SharedMemory* getSharedMemory(void) {
    int fd = open(SHARED_MEMORY_PATH, O_RDWR | O_CREAT, 0666);
    if (fd == -1) {
        NSLog(@"Failed to open shared memory");
        return NULL;
    }
    
    // Set the size of the file
    ftruncate(fd, sizeof(SharedMemory));
    
    // Map the file into memory
    SharedMemory* shared = mmap(NULL, sizeof(SharedMemory), PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
    close(fd);
    
    if (shared == MAP_FAILED) {
        NSLog(@"Failed to map shared memory");
        return NULL;
    }
    
    return shared;
}

@interface MacWMFX : NSObject

+ (instancetype)sharedInstance;
- (void)loadFeaturesFromConfig;
- (void)initializeGlobals;
- (NSColor *)colorFromHexString:(NSString *)hexString;
- (void)startListeningForUpdates;
- (void)handleSettingsUpdate:(NSNotification *)notification;

@end

@implementation MacWMFX

+ (void)load {
    // Check if we're running from CLI by looking at the process name
    NSString *processName = [[NSProcessInfo processInfo] processName];
    if ([processName isEqualToString:@"macwmfx"]) {
        gRunningFromCLI = YES;
        return;  // Skip loading config if running from CLI
    }
    
    // Initialize the singleton and load config on startup
    MacWMFX *instance = [self sharedInstance];
    [instance loadFeaturesFromConfig];
    [instance startListeningForUpdates];
}

+ (instancetype)sharedInstance {
    static MacWMFX *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[MacWMFX alloc] init];
        [sharedInstance initializeGlobals];
    });
    return sharedInstance;
}

- (NSColor *)colorFromHexString:(NSString *)hexString {
    if (!hexString) return nil;
    
    unsigned int hexInt = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    [scanner scanHexInt:&hexInt];
    
    return [NSColor colorWithRed:((hexInt & 0xFF0000) >> 16) / 255.0
                          green:((hexInt & 0x00FF00) >> 8) / 255.0
                           blue:(hexInt & 0x0000FF) / 255.0
                          alpha:1.0];
}

- (void)initializeGlobals {
    gIsEnabled = YES;
    gBlurPasses = 1;
    gBlurRadius = 10.0;
    gTransparency = 1.0;
    
    gDisableTitlebar = NO;
    gDisableTrafficLights = NO;
    gDisableWindowSizeConstraints = NO;
    
    gOutlineEnabled = YES;
    gOutlineWidth = 4.0;
    gOutlineCornerRadius = 10.0;
    gOutlineType = @"inline";
    gOutlineActiveColor = [NSColor whiteColor];
    gOutlineInactiveColor = [NSColor grayColor];
    
    gSystemColorSchemeVariant = @"dark";
}

- (void)loadFeaturesFromConfig {
    NSString *configPath = [NSString stringWithFormat:@"%@/.config/macwmfx/config", NSHomeDirectory()];
    NSData *configData = [NSData dataWithContentsOfFile:configPath];
    
    if (!configData) {
        NSLog(@"No config found at %@", configPath);
        return;
    }
    
    NSError *error = nil;
    NSDictionary *config = [NSJSONSerialization JSONObjectWithData:configData options:0 error:&error];
    
    if (error || !config) {
        NSLog(@"Error parsing config file: %@", error);
        return;
    }
    
    // Window Appearance
    gBlurPasses = [config[@"blurPasses"] integerValue] ?: gBlurPasses;
    gBlurRadius = [config[@"blurRadius"] doubleValue] ?: gBlurRadius;
    gTransparency = [config[@"transparency"] doubleValue] ?: gTransparency;
    gDisableWindowShadow = [config[@"disableWindowShadow"] boolValue];
    
    // Window Behavior
    gDisableTitlebar = [config[@"disableTitlebar"] boolValue];
    gDisableTrafficLights = [config[@"disableTrafficLights"] boolValue];
    gDisableWindowSizeConstraints = [config[@"disableWindowSizeConstraints"] boolValue];
    
    // Window Outline
    gOutlineEnabled = [config[@"outlineWindow"][@"enabled"] boolValue];
    gOutlineWidth = [config[@"outlineWindow"][@"width"] doubleValue] ?: gOutlineWidth;
    gOutlineCornerRadius = [config[@"outlineWindow"][@"cornerRadius"] doubleValue] ?: gOutlineCornerRadius;
    
    NSString *outlineType = config[@"outlineWindow"][@"type"];
    if (outlineType) {
        gOutlineType = [outlineType copy];
    }
    
    NSString *activeColor = config[@"outlineWindow"][@"activeColor"];
    if (activeColor) {
        gOutlineActiveColor = [self colorFromHexString:activeColor];
    }
    
    NSString *inactiveColor = config[@"outlineWindow"][@"inactiveColor"];
    if (inactiveColor) {
        gOutlineInactiveColor = [self colorFromHexString:inactiveColor];
    }
    
    // System Appearance
    NSString *colorScheme = config[@"systemColorSchemeVariant"];
    if (colorScheme) {
        gSystemColorSchemeVariant = [colorScheme copy];
    }
    
    NSLog(@"Config loaded from JSON file");
}

- (void)startListeningForUpdates {
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self
                                                      selector:@selector(handleSettingsUpdate:)
                                                          name:@"com.macwmfx.settingsChanged"
                                                        object:nil];
}

- (void)handleSettingsUpdate:(NSNotification *)notification {
    SharedMemory* shared = getSharedMemory();
    if (!shared) return;
    
    if (shared->updateNeeded) {
        // Update globals from shared memory
        gOutlineEnabled = shared->outlineEnabled;
        gOutlineWidth = shared->outlineWidth;
        gOutlineCornerRadius = shared->outlineCornerRadius;
        
        // Reset update flag
        shared->updateNeeded = NO;
        
        // Update all windows on the main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            // Get all windows, including those from other apps
            CFArrayRef windowList = CGWindowListCopyWindowInfo(kCGWindowListOptionOnScreenOnly, kCGNullWindowID);
            if (windowList) {
                NSArray *windows = CFBridgingRelease(windowList);
                for (NSDictionary *windowInfo in windows) {
                    NSNumber *windowID = windowInfo[(id)kCGWindowNumber];
                    NSWindow *window = [NSApp windowWithWindowNumber:windowID.integerValue];
                    if (window && [window respondsToSelector:@selector(updateBorderStyle)]) {
                        [window performSelector:@selector(updateBorderStyle)];
                        [window display];
                    }
                }
            }
        });
    }
}

@end
