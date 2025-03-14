//
//  configParser.m
//  macwmfx
//
//  Created by Alex "aspauldingcode" on 01/09/25.
//  Copyright (c) 2025 Alex "aspauldingcode". All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "../headers/macwmfx_globals.h"

@interface ConfigParser ()
@property (nonatomic, strong) NSFileHandle *configFileHandle;
@property (nonatomic, strong) dispatch_source_t fileMonitor;
@property (nonatomic, copy) NSString *configPath;
@end

@implementation ConfigParser

+ (instancetype)sharedInstance {
    static ConfigParser *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[ConfigParser alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        NSString *appSupportPath = @"/Library/Application Support/macwmfx";
        self.configPath = [appSupportPath stringByAppendingPathComponent:@"config.json"];
    }
    return self;
}

- (void)startFileMonitor {
    if (!gHotloadConfig.enabled) return;
    
    // Stop existing monitor if any
    [self stopFileMonitor];
    
    int fd = open([self.configPath UTF8String], O_EVTONLY);
    if (fd < 0) {
        NSLog(@"[macwmfx] Failed to open config file for monitoring: %s", strerror(errno));
        return;
    }
    
    // Create dispatch source for monitoring file descriptor
    self.fileMonitor = dispatch_source_create(DISPATCH_SOURCE_TYPE_VNODE, fd,
                                            DISPATCH_VNODE_DELETE | DISPATCH_VNODE_WRITE | DISPATCH_VNODE_EXTEND,
                                            dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));
    
    // Set up event handler
    ConfigParser *blockSelf = self;
    dispatch_source_set_event_handler(self.fileMonitor, ^{
        unsigned long flags = dispatch_source_get_data(blockSelf.fileMonitor);
        
        // Add a small delay to ensure file is fully written
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (flags & (DISPATCH_VNODE_DELETE | DISPATCH_VNODE_WRITE | DISPATCH_VNODE_EXTEND)) {
                NSLog(@"[macwmfx] Config file changed, reloading...");
                [blockSelf loadConfig];
                [blockSelf notifyConfigChanged];
                
                // If file was deleted, restart monitor
                if (flags & DISPATCH_VNODE_DELETE) {
                    [blockSelf startFileMonitor];
                }
            }
        });
    });
    
    // Set up cancellation handler
    dispatch_source_set_cancel_handler(self.fileMonitor, ^{
        close(fd);
    });
    
    // Start monitoring
    dispatch_resume(self.fileMonitor);
    NSLog(@"[macwmfx] Started file monitor for config changes");
}

- (void)stopFileMonitor {
    if (self.fileMonitor) {
        dispatch_source_cancel(self.fileMonitor);
        self.fileMonitor = nil;
    }
}

- (void)updateAllWindows {
    NSArray *windows = [NSApp windows];
    if (!windows) {
        NSLog(@"[macwmfx] No windows found to update");
        return;
    }

    for (NSWindow *window in windows) {
        @try {
            // Skip if not a regular window
            if (!(window.styleMask & NSWindowStyleMaskTitled)) {
                continue;
            }

            // Skip if window is being dealloc'd or invalid
            if (!window || ![window isKindOfClass:[NSWindow class]]) {
                continue;
            }

            // Update window shadows based on config
            @try {
                [window setHasShadow:gShadowConfig.enabled];
            } @catch (NSException *e) {
                NSLog(@"[macwmfx] Failed to update window shadow: %@", e);
            }

            // Update window borders if supported
            if ([window respondsToSelector:@selector(updateBorderStyle)]) {
                @try {
                    [window performSelector:@selector(updateBorderStyle)];
                } @catch (NSException *e) {
                    NSLog(@"[macwmfx] Failed to update border style: %@", e);
                }
            }

            // Update titlebar if needed
            if (!gTitlebarConfig.enabled) {
                @try {
                    window.titlebarAppearsTransparent = YES;
                    window.titleVisibility = NSWindowTitleHidden;
                    window.styleMask |= NSWindowStyleMaskFullSizeContentView;
                } @catch (NSException *e) {
                    NSLog(@"[macwmfx] Failed to update titlebar: %@", e);
                }
            }

            // Update traffic lights if needed
            if (!gTrafficLightsConfig.enabled) {
                @try {
                    NSButton *closeButton = [window standardWindowButton:NSWindowCloseButton];
                    NSButton *minimizeButton = [window standardWindowButton:NSWindowMiniaturizeButton];
                    NSButton *zoomButton = [window standardWindowButton:NSWindowZoomButton];
                    if (closeButton && closeButton.superview) {
                        for (NSView *view in closeButton.superview.subviews) {
                            if ([view isKindOfClass:[NSButton class]]) {
                                [(NSButton *)view setHidden:YES];
                            }
                        }
                    }
                    if (minimizeButton && minimizeButton.superview) {
                        for (NSView *view in minimizeButton.superview.subviews) {
                            if ([view isKindOfClass:[NSButton class]]) {
                                [(NSButton *)view setHidden:YES];
                            }
                        }
                    }
                    if (zoomButton && zoomButton.superview) {
                        for (NSView *view in zoomButton.superview.subviews) {
                            if ([view isKindOfClass:[NSButton class]]) {
                                [(NSButton *)view setHidden:YES];
                            }
                        }
                    }
                } @catch (NSException *e) {
                    NSLog(@"[macwmfx] Failed to update traffic lights: %@", e);
                }
            }

            // Force window to update, but safely
            @try {
                [window display];
            } @catch (NSException *e) {
                NSLog(@"[macwmfx] Failed to display window: %@", e);
            }

        } @catch (NSException *e) {
            NSLog(@"[macwmfx] Failed to update window: %@", e);
            continue;  // Skip to next window on error
        }
    }

    // Post notification for other parts of the app
    @try {
        [[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"com.macwmfx.configChanged"
                                                                    object:nil
                                                                  userInfo:nil
                                                        deliverImmediately:YES];
    } @catch (NSException *e) {
        NSLog(@"[macwmfx] Failed to post config changed notification: %@", e);
    }
    
    NSLog(@"[macwmfx] Finished updating all windows");
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

- (void)notifyConfigChanged {
    // Send notification on both centers to ensure delivery
    [[NSNotificationCenter defaultCenter] postNotificationName:@"com.macwmfx.configChanged"
                                                      object:nil];
    
    [[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"com.macwmfx.configChanged"
                                                                object:nil
                                                              userInfo:nil
                                                    deliverImmediately:YES];
    
    NSLog(@"[macwmfx] Posted config changed notifications");
}

- (void)loadConfig {
    NSData *configData = [NSData dataWithContentsOfFile:self.configPath];
    
    if (!configData) {
        NSLog(@"[macwmfx] No config found at %@", self.configPath);
        return;
    }
    
    NSError *error = nil;
    NSDictionary *config = [NSJSONSerialization JSONObjectWithData:configData options:0 error:&error];
    
    if (error || !config) {
        NSLog(@"[macwmfx] Error parsing config file: %@", error);
        return;
    }
    
    // Parse Hotload Configuration
    NSDictionary *hotloadConfig = config[@"hotload"];
    if (hotloadConfig) {
        gHotloadConfig.enabled = [hotloadConfig[@"enabled"] boolValue];
        gHotloadConfig.interval = [hotloadConfig[@"interval"] integerValue] ?: 1;
        
        // Start or stop file monitoring based on config
        if (gHotloadConfig.enabled && !self.fileMonitor) {
            [self startFileMonitor];
        } else if (!gHotloadConfig.enabled && self.fileMonitor) {
            [self stopFileMonitor];
        }
    }
    
    // Parse Window Configuration
    NSDictionary *windowConfig = config[@"window"];
    if (windowConfig) {
        // Window Blur
        NSDictionary *blurConfig = windowConfig[@"blur"];
        if (blurConfig) {
            gBlurConfig.enabled = [blurConfig[@"enabled"] boolValue];
            gBlurConfig.passes = [blurConfig[@"passes"] integerValue] ?: gBlurConfig.passes;
            gBlurConfig.radius = [blurConfig[@"radius"] doubleValue] ?: gBlurConfig.radius;
        }
        
        // Window Titlebar
        NSDictionary *titlebarConfig = windowConfig[@"titlebar"];
        if (titlebarConfig) {
            gTitlebarConfig.enabled = [titlebarConfig[@"enabled"] boolValue];
            gTitlebarConfig.forceClassic = [titlebarConfig[@"forceClassic"] boolValue];
            
            // Parse custom color settings using active and inactive state colors
            NSDictionary *customColor = titlebarConfig[@"customColor"];
            if (customColor) {
                gTitlebarConfig.customColor.enabled = [customColor[@"enabled"] boolValue];
                if (customColor[@"activeBackground"]) {
                    gTitlebarConfig.customColor.activeBackground = [self colorFromHexString:customColor[@"activeBackground"]];
                }
                if (customColor[@"activeForeground"]) {
                    gTitlebarConfig.customColor.activeForeground = [self colorFromHexString:customColor[@"activeForeground"]];
                }
                if (customColor[@"inactiveBackground"]) {
                    gTitlebarConfig.customColor.inactiveBackground = [self colorFromHexString:customColor[@"inactiveBackground"]];
                }
                if (customColor[@"inactiveForeground"]) {
                    gTitlebarConfig.customColor.inactiveForeground = [self colorFromHexString:customColor[@"inactiveForeground"]];
                }
            }
            gTitlebarConfig.style = [titlebarConfig[@"style"] copy] ?: @"modern";
            gTitlebarConfig.size = [titlebarConfig[@"size"] doubleValue] ?: 22.0;
            
            // Custom Title
            NSDictionary *customTitleConfig = titlebarConfig[@"customTitle"];
            if (customTitleConfig) {
                gCustomTitleConfig.enabled = [customTitleConfig[@"enabled"] boolValue];
                NSString *titleStr = [customTitleConfig[@"title"] description];
                if (titleStr) {
                    // Free existing title if necessary
                    if (gCustomTitleConfig.title != NULL) {
                        free((void*)gCustomTitleConfig.title);
                        gCustomTitleConfig.title = NULL;
                    }
                    // Allocate and copy the new title string
                    const char *utf8Title = [titleStr UTF8String];
                    if (utf8Title) {
                        gCustomTitleConfig.title = strdup(utf8Title);
                        NSLog(@"[macwmfx] Set custom title to: %s", gCustomTitleConfig.title);
                    }
                }
            }
        }
        
        // Window Traffic Lights
        NSDictionary *trafficLightsConfig = windowConfig[@"trafficLights"];
        if (trafficLightsConfig) {
            gTrafficLightsConfig.enabled = [trafficLightsConfig[@"enabled"] boolValue];
            NSLog(@"[macwmfx] Traffic lights enabled: %d", gTrafficLightsConfig.enabled);
            
            // Parse custom colors
            NSDictionary *customColor = trafficLightsConfig[@"customColor"];
            if (customColor) {
                gTrafficLightsConfig.customColor.enabled = [customColor[@"enabled"] boolValue];
                
                // Parse active state colors
                NSDictionary *activeColors = customColor[@"active"];
                if (activeColors) {
                    gTrafficLightsConfig.customColor.active.stop = activeColors[@"stop"];
                    gTrafficLightsConfig.customColor.active.yield = activeColors[@"yield"];
                    gTrafficLightsConfig.customColor.active.go = activeColors[@"go"];
                }
                
                // Parse inactive state colors
                NSDictionary *inactiveColors = customColor[@"inactive"];
                if (inactiveColors) {
                    gTrafficLightsConfig.customColor.inactive.stop = inactiveColors[@"stop"];
                    gTrafficLightsConfig.customColor.inactive.yield = inactiveColors[@"yield"];
                    gTrafficLightsConfig.customColor.inactive.go = inactiveColors[@"go"];
                }
                
                // Parse hover state colors
                NSDictionary *hoverColors = customColor[@"hover"];
                if (hoverColors) {
                    gTrafficLightsConfig.customColor.hover.stop = hoverColors[@"stop"];
                    gTrafficLightsConfig.customColor.hover.yield = hoverColors[@"yield"];
                    gTrafficLightsConfig.customColor.hover.go = hoverColors[@"go"];
                }
                
                NSLog(@"[macwmfx] Traffic lights custom colors loaded for active/inactive/hover states");
            }
            
            gTrafficLightsConfig.style = [trafficLightsConfig[@"style"] copy] ?: @"macOS";
            gTrafficLightsConfig.shape = [trafficLightsConfig[@"shape"] copy] ?: @"circle";
            gTrafficLightsConfig.order = [trafficLightsConfig[@"order"] copy] ?: @"stop-yield-go";  // Default macOS order
            gTrafficLightsConfig.size = [trafficLightsConfig[@"size"] doubleValue] ?: 12.0;
            gTrafficLightsConfig.padding = [trafficLightsConfig[@"padding"] doubleValue] ?: 0;
            gTrafficLightsConfig.position = [trafficLightsConfig[@"position"] copy] ?: @"top-left";
        }
        
        // Window Shadow
        NSDictionary *shadowConfig = windowConfig[@"shadow"];
        if (shadowConfig) {
            BOOL oldEnabled = gShadowConfig.enabled;
            gShadowConfig.enabled = [shadowConfig[@"enabled"] boolValue];
            
            // Parse custom color settings
            NSDictionary *customColor = shadowConfig[@"customColor"];
            if (customColor) {
                gShadowConfig.customColor.enabled = [customColor[@"enabled"] boolValue];
                gShadowConfig.customColor.active = [customColor[@"active"] copy];
                gShadowConfig.customColor.inactive = [customColor[@"inactive"] copy];
            }
            
            if (oldEnabled != gShadowConfig.enabled) {
                NSLog(@"[macwmfx] Shadow config changed from %d to %d", oldEnabled, gShadowConfig.enabled);
            }
        }
        
        // Window Size Constraints
        NSDictionary *sizeConstraintsConfig = windowConfig[@"sizeConstraints"];
        if (sizeConstraintsConfig) {
            gWindowSizeConstraintsConfig.enabled = [sizeConstraintsConfig[@"enabled"] boolValue];
        }
        
        // Window Outline
        NSDictionary *outlineConfig = windowConfig[@"outline"];
        if (outlineConfig) {
            gOutlineConfig.enabled = [outlineConfig[@"enabled"] boolValue];
            gOutlineConfig.type = [outlineConfig[@"type"] copy];
            gOutlineConfig.width = [outlineConfig[@"width"] doubleValue];
            gOutlineConfig.cornerRadius = [outlineConfig[@"cornerRadius"] doubleValue];
            
            // Parse custom color settings
            NSDictionary *customColor = outlineConfig[@"customColor"];
            if (customColor) {
                gOutlineConfig.customColor.enabled = [customColor[@"enabled"] boolValue];
                gOutlineConfig.customColor.active = [self colorFromHexString:customColor[@"active"]];
                gOutlineConfig.customColor.inactive = [self colorFromHexString:customColor[@"inactive"]];
                gOutlineConfig.customColor.stacked = [self colorFromHexString:customColor[@"stacked"]];
            }
            
            NSLog(@"[macwmfx] Parsed outline config: enabled=%d, type=%@, width=%.1f, cornerRadius=%.1f, customColor.enabled=%d",
                  gOutlineConfig.enabled,
                  gOutlineConfig.type,
                  gOutlineConfig.width,
                  gOutlineConfig.cornerRadius,
                  gOutlineConfig.customColor.enabled);
        }
        
        // Window Transparency
        NSDictionary *transparencyConfig = windowConfig[@"transparency"];
        if (transparencyConfig) {
            gTransparencyConfig.enabled = [transparencyConfig[@"enabled"] boolValue];
            gTransparencyConfig.value = [transparencyConfig[@"value"] doubleValue] ?: 0.5;
        }
    }
    
    // System Color Scheme
    NSDictionary *systemColorConfig = config[@"systemColorScheme"];
    if (systemColorConfig) {
        gSystemColorConfig.variant = [systemColorConfig[@"variant"] copy] ?: @"dark";
        gSystemColorConfig.slug = [systemColorConfig[@"slug"] copy] ?: @"gruvbox-dark-soft";
        if (systemColorConfig[@"colors"]) {
            [self parseColorScheme:systemColorConfig[@"colors"]];
        }
    }
    
    NSLog(@"[macwmfx] Config loaded from %@", self.configPath);
}

- (void)parseColorScheme:(NSDictionary *)colors {
    gSystemColorConfig.colors.base00 = [self colorFromHexString:colors[@"base00"]];
    gSystemColorConfig.colors.base01 = [self colorFromHexString:colors[@"base01"]];
    gSystemColorConfig.colors.base02 = [self colorFromHexString:colors[@"base02"]];
    gSystemColorConfig.colors.base03 = [self colorFromHexString:colors[@"base03"]];
    gSystemColorConfig.colors.base04 = [self colorFromHexString:colors[@"base04"]];
    gSystemColorConfig.colors.base05 = [self colorFromHexString:colors[@"base05"]];
    gSystemColorConfig.colors.base06 = [self colorFromHexString:colors[@"base06"]];
    gSystemColorConfig.colors.base07 = [self colorFromHexString:colors[@"base07"]];
    gSystemColorConfig.colors.base08 = [self colorFromHexString:colors[@"base08"]];
    gSystemColorConfig.colors.base09 = [self colorFromHexString:colors[@"base09"]];
    gSystemColorConfig.colors.base0A = [self colorFromHexString:colors[@"base0A"]];
    gSystemColorConfig.colors.base0B = [self colorFromHexString:colors[@"base0B"]];
    gSystemColorConfig.colors.base0C = [self colorFromHexString:colors[@"base0C"]];
    gSystemColorConfig.colors.base0D = [self colorFromHexString:colors[@"base0D"]];
    gSystemColorConfig.colors.base0E = [self colorFromHexString:colors[@"base0E"]];
    gSystemColorConfig.colors.base0F = [self colorFromHexString:colors[@"base0F"]];
}

- (void)parseTrafficLightsConfig:(NSDictionary *)config {
    if (!config) return;
    
    gTrafficLightsConfig.enabled = [config[@"enabled"] boolValue];
    
    // Parse custom colors
    NSDictionary *customColor = config[@"customColor"];
    if (customColor) {
        gTrafficLightsConfig.customColor.enabled = [customColor[@"enabled"] boolValue];
        
        // Parse active state colors
        NSDictionary *activeColors = customColor[@"active"];
        if (activeColors) {
            gTrafficLightsConfig.customColor.active.stop = activeColors[@"stop"];
            gTrafficLightsConfig.customColor.active.yield = activeColors[@"yield"];
            gTrafficLightsConfig.customColor.active.go = activeColors[@"go"];
        }
        
        // Parse inactive state colors
        NSDictionary *inactiveColors = customColor[@"inactive"];
        if (inactiveColors) {
            gTrafficLightsConfig.customColor.inactive.stop = inactiveColors[@"stop"];
            gTrafficLightsConfig.customColor.inactive.yield = inactiveColors[@"yield"];
            gTrafficLightsConfig.customColor.inactive.go = inactiveColors[@"go"];
        }
        
        // Parse hover state colors
        NSDictionary *hoverColors = customColor[@"hover"];
        if (hoverColors) {
            gTrafficLightsConfig.customColor.hover.stop = hoverColors[@"stop"];
            gTrafficLightsConfig.customColor.hover.yield = hoverColors[@"yield"];
            gTrafficLightsConfig.customColor.hover.go = hoverColors[@"go"];
        }
        
        NSLog(@"[macwmfx] Traffic lights custom colors loaded for active/inactive/hover states");
    }
    
    // Parse style settings
    gTrafficLightsConfig.style = [config[@"style"] copy] ?: @"macOS";
    gTrafficLightsConfig.shape = [config[@"shape"] copy] ?: @"circle";
    gTrafficLightsConfig.order = [config[@"order"] copy] ?: @"stop-yield-go";  // Default macOS order
    gTrafficLightsConfig.size = [config[@"size"] doubleValue] ?: 12.0;
    gTrafficLightsConfig.padding = [config[@"padding"] doubleValue] ?: 0;
    gTrafficLightsConfig.position = [config[@"position"] copy] ?: @"top-left";
    
    NSLog(@"[macwmfx] Parsed traffic lights config: enabled=%d, style=%@, shape=%@, order=%@, position=%@, size=%.1f, padding=%.1f",
          gTrafficLightsConfig.enabled,
          gTrafficLightsConfig.style,
          gTrafficLightsConfig.shape,
          gTrafficLightsConfig.order,
          gTrafficLightsConfig.position,
          gTrafficLightsConfig.size,
          gTrafficLightsConfig.padding);
}

@end
