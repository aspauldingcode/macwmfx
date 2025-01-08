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
BlurConfig gBlurConfig = {
    .enabled = YES,
    .passes = 1,
    .radius = 10.0
};
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
- (void)handleWindowUpdate:(NSNotification *)notification;

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
    gBlurConfig.enabled = YES;
    gBlurConfig.passes = 1;
    gBlurConfig.radius = 10.0;
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
    NSString *configPath = @"/Library/Application Support/macwmfx/config";
    
    // Create directory if it doesn't exist
    NSString *directoryPath = @"/Library/Application Support/macwmfx";
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:directoryPath]) {
        NSError *error = nil;
        if (![fileManager createDirectoryAtPath:directoryPath withIntermediateDirectories:YES attributes:nil error:&error]) {
            NSLog(@"Failed to create directory: %@", error);
        }
    }
    
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
    NSDictionary *blurConfig = config[@"blur"];
    if (blurConfig) {
        gBlurConfig.enabled = [blurConfig[@"enabled"] boolValue];
        gBlurConfig.passes = [blurConfig[@"passes"] integerValue] ?: gBlurConfig.passes;
        gBlurConfig.radius = [blurConfig[@"radius"] doubleValue] ?: gBlurConfig.radius;
    }
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
                                                      selector:@selector(handleWindowUpdate:)
                                                          name:@"com.macwmfx.updateWindow"
                                                        object:nil];
}

- (void)handleWindowUpdate:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        // Get the window number from the notification
        NSString *windowNumberStr = notification.object;
        if (!windowNumberStr) return;
        
        NSInteger windowNumber = [windowNumberStr integerValue];
        NSWindow *window = [NSApp windowWithWindowNumber:windowNumber];
        
        if (window && [window respondsToSelector:@selector(updateBorderStyle)]) {
            [window performSelector:@selector(updateBorderStyle)];
            [window display];
        }
    });
}

@end
