//
//  macwmfx_server.m
//  macwmfx
//
//  Created by Alex "aspauldingcode" on 01/09/25.
//  Copyright (c) 2025 Alex "aspauldingcode". All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <XPC/xpc.h>
#import <dlfcn.h>
#import "macwmfx_server.h"
#import "../shared/headers/macwmfx_globals.h"
#import "../shared/headers/configParser.h"
#import "../shared/macwmfx_logging.h"
#import "../main/macwmfx.h"
#import "../modules/menubar/features/ribbonbar/RibbonBarShared.h"
#include <objc/message.h>

// Ribbon bar constants and types
#define kRibbonHeight 22
#define kRibbonInset 8
#define kRibbonPadding 4

// Ribbon bar function types
typedef void (*GumInterceptorReplaceFuncType)(void *interceptor, void *function_address, void *replacement_function, void *user_data);
typedef void (*GumInterceptorBeginTransactionFuncType)(void *interceptor);
typedef void (*GumInterceptorEndTransactionFuncType)(void *interceptor);

// Ribbon bar globals
void *gHook;
GumInterceptorReplaceFuncType GumInterceptorReplaceFunc;
GumInterceptorBeginTransactionFuncType GumInterceptorBeginTransactionFunc;
GumInterceptorEndTransactionFuncType GumInterceptorEndTransactionFunc;

// Ribbon bar function pointers
void (*_ForceTitlebarOld)(id, SEL, NSWindowStyleMask);
NSView* (*_TitlebarContainerViewOld)(id, SEL);

// Ribbon bar forward declarations
void ForceTitlebar(id self, SEL _cmd, NSWindowStyleMask style);
NSView* TitlebarContainerView(NSView *self, SEL _cmd);
CGFloat FindVisualEffectViewSecondOrHighestX(NSView *parentView);
void DisplayMenuAsContextual(NSMenu *menu, NSView *view, NSPoint location);

// Forward declare NSThemeFrame to avoid undeclared identifier error
@class NSThemeFrame;

// Ribbon bar utility functions
void DisplayMenuAsContextual(NSMenu *menu, NSView *view, NSPoint location) {
    [menu popUpMenuPositioningItem:nil atLocation:location inView:view];
}

CGFloat FindVisualEffectViewSecondOrHighestX(NSView *parentView) {
    if (!parentView) return 0;

    NSMutableArray<NSVisualEffectView *> *effectViews = [NSMutableArray array];
    for (NSView *subview in parentView.subviews) {
        if ([subview isKindOfClass:[NSVisualEffectView class]]) {
            [effectViews addObject:(NSVisualEffectView *)subview];
        }
    }

    if (effectViews.count >= 2) {
        [effectViews sortUsingComparator:^NSComparisonResult(NSVisualEffectView *view1, NSVisualEffectView *view2) {
            CGFloat x1 = view1.frame.origin.x;
            CGFloat x2 = view2.frame.origin.x;
            return (x1 > x2) ? NSOrderedDescending : (x1 < x2) ? NSOrderedAscending : NSOrderedSame;
        }];
        return effectViews[1].frame.origin.x;
    } else if (effectViews.count == 1) {
        return effectViews[0].frame.origin.x;
    }
    return 0;
}

void ForceTitlebar(id self, SEL _cmd, NSWindowStyleMask style) {
    _ForceTitlebarOld(self, _cmd, style | NSWindowStyleMaskTitled);
}

NSView* TitlebarContainerView(NSView *self, SEL _cmd) {
    NSView *containerView = _TitlebarContainerViewOld(self, _cmd);
    if (!containerView) return nil;

    if ([self window].isSheet || [self window].isModalPanel || [self window].isFloatingPanel) {
        return containerView;
    }

    if (containerView.frame.size.height < 5) return containerView;

    int startingx = FindVisualEffectViewSecondOrHighestX(containerView);
    if (startingx == 0) {
        NSWindow *_window = [self window];
        startingx = [_window standardWindowButton:NSWindowZoomButton].frame.origin.x + kRibbonInset;
    }

    // Clear previous custom subviews
    for (NSView *subview in [containerView.subviews copy]) {
        if (subview.tag == 9898) {
            [subview removeFromSuperview];
        }
    }

    NSMenu *mainMenu = [NSApp mainMenu];
    if (!mainMenu) return containerView;

    CGFloat xPos = startingx + kRibbonInset + kRibbonPadding;
    CGFloat yPos;
    BOOL hasToolbar = NO;
    SEL hasToolbarSel = sel_registerName("_hasToolbar");
    if ([(id)self respondsToSelector:hasToolbarSel]) {
        hasToolbar = ((BOOL (*)(id, SEL))objc_msgSend)((id)self, hasToolbarSel);
    }
    if (hasToolbar) {
        yPos = containerView.frame.size.height - kRibbonHeight - kRibbonInset;
    } else {
        yPos = (containerView.bounds.size.height - 22) / 2.0;
    }

    int i = 0;
    CGFloat padding = kRibbonPadding;

    for (NSMenuItem *menuItem in mainMenu.itemArray) {
        if (menuItem.hasSubmenu) {
            ContextualMenuButton *button = [[ContextualMenuButton alloc] initWithFrame:NSMakeRect(xPos, yPos, 80, kRibbonHeight)];

            NSString *buttonTitle;
            if (menuItem.title.length < 1 && i == 0) {
                buttonTitle = [NSBundle mainBundle].infoDictionary[@"CFBundleDisplayName"];
            } else {
                buttonTitle = menuItem.title;
            }

            button.title = buttonTitle;

            NSDictionary *attributes = @{NSFontAttributeName: button.font};
            NSRect titleRect = [buttonTitle boundingRectWithSize:NSMakeSize(CGFLOAT_MAX, kRibbonHeight)
                                                          options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                                       attributes:attributes
                                                          context:nil];

            CGFloat requiredWidth = titleRect.size.width + padding * 2;
            button.frame = NSMakeRect(xPos, yPos, requiredWidth, kRibbonHeight);

            button.bezelStyle = NSBezelStyleRounded;
            button.bordered = false;
            button.tag = 9898;
            button.associatedMenu = menuItem.submenu;
            button.target = button;
            button.action = @selector(displayAssociatedMenu:);

            [containerView addSubview:button];
            xPos += requiredWidth + padding;
        }
        i++;
    }

    return containerView;
}

// Hook utility function
extern void AddHook(Class class, SEL originalSelector, SEL swizzledSelector, IMP implementation, Method *originalMethodStorage, BOOL isClassMethod);

// Global server instance
macwmfxServer *gmacwmfxServer = nil;

// XPC service name
static const char *kmacwmfxServiceName = "com.aspauldingcode.macwmfx.server";

@implementation macwmfxServerMessage
@end

@implementation macwmfxServerResponse
@end

@implementation macwmfxServer {
    xpc_connection_t _serviceConnection;
    dispatch_queue_t _serverQueue;
    BOOL _isRunning;
    NSMutableArray<xpc_connection_t> *_clientConnections;
}

+ (instancetype)sharedServer {
    static macwmfxServer *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _serverQueue = dispatch_queue_create("com.aspauldingcode.macwmfx.server", DISPATCH_QUEUE_SERIAL);
        _clientConnections = [NSMutableArray array];
        _isRunning = NO;
    }
    return self;
}

- (void)startServer {
    if (_isRunning) {
        MACWMFX_LOG_INFO(macwmfx_log_server, "Server already running");
        return;
    }

    dispatch_async(_serverQueue, ^{
        MACWMFX_LOG_INFO(macwmfx_log_server, "Starting server...");

        // Create XPC service
        _serviceConnection = xpc_connection_create_mach_service(kmacwmfxServiceName, _serverQueue, XPC_CONNECTION_MACH_SERVICE_LISTENER);

        if (!_serviceConnection) {
            MACWMFX_LOG_ERROR(macwmfx_log_server, "Failed to create XPC service");
            return;
        }

        // Set up event handler
        xpc_connection_set_event_handler(_serviceConnection, ^(xpc_object_t event) {
            [self handleXPCEvent:event];
        });

        // Activate the connection
        xpc_connection_activate(_serviceConnection);

        _isRunning = YES;
        MACWMFX_LOG_INFO(macwmfx_log_server, "Server started successfully");

        // Load initial configuration
        [self loadConfiguration];
    });
}

- (void)stopServer {
    if (!_isRunning) {
        MACWMFX_LOG_INFO(macwmfx_log_server, "Server not running");
        return;
    }

    dispatch_async(_serverQueue, ^{
        MACWMFX_LOG_INFO(macwmfx_log_server, "Stopping server...");

        // Close all client connections
        for (xpc_connection_t connection in _clientConnections) {
            xpc_connection_cancel(connection);
        }
        [_clientConnections removeAllObjects];

        // Cancel service connection
        if (_serviceConnection) {
            xpc_connection_cancel(_serviceConnection);
            _serviceConnection = NULL;
        }

        _isRunning = NO;
        MACWMFX_LOG_INFO(macwmfx_log_server, "Server stopped");
    });
}

- (BOOL)isServerRunning {
    return _isRunning;
}

- (void)handleXPCEvent:(xpc_object_t)event {
    xpc_type_t type = xpc_get_type(event);

    if (type == XPC_TYPE_CONNECTION) {
        // New client connection
        xpc_connection_t clientConnection = (xpc_connection_t)event;
        [self handleClientConnection:clientConnection];
    } else if (type == XPC_TYPE_DICTIONARY) {
        // Message from client
        [self handleClientMessage:event];
    }
}

- (void)handleClientConnection:(xpc_connection_t)connection {
    MACWMFX_LOG_INFO(macwmfx_log_server, "New client connected");

    // Add to client connections
    [_clientConnections addObject:connection];

    // Set up event handler for this connection
    xpc_connection_set_event_handler(connection, ^(xpc_object_t event) {
        xpc_type_t type = xpc_get_type(event);

        if (type == XPC_TYPE_DICTIONARY) {
            [self handleClientMessage:event];
        } else if (type == XPC_TYPE_ERROR) {
            // Client disconnected
            MACWMFX_LOG_INFO(macwmfx_log_server, "Client disconnected");
            [self->_clientConnections removeObject:connection];
        }
    });

    xpc_connection_activate(connection);
}

- (void)handleClientMessage:(xpc_object_t)message {
    // Extract command and data from XPC message
    int64_t commandValue = xpc_dictionary_get_int64(message, "command");
    macwmfxServerCommand command = (macwmfxServerCommand)commandValue;

    id data = nil;
    xpc_object_t dataObject = xpc_dictionary_get_value(message, "data");
    if (dataObject && xpc_get_type(dataObject) == XPC_TYPE_DATA) {
        size_t dataSize = xpc_data_get_length(dataObject);
        const void *dataBytes = xpc_data_get_bytes_ptr(dataObject);
        if (dataSize > 0 && dataBytes) {
            data = [NSKeyedUnarchiver unarchivedObjectOfClass:[NSObject class] fromData:[NSData dataWithBytes:dataBytes length:dataSize] error:nil];
        }
    }

    // Handle the command
    macwmfxServerResponse *response = [self handleCommand:command withData:data];

    // Send response back to client
    xpc_connection_t sender = xpc_dictionary_get_remote_connection(message);
    if (sender) {
        [self sendResponse:response toConnection:sender];
    }
}

- (void)sendResponse:(macwmfxServerResponse *)response toConnection:(xpc_connection_t)connection {
    xpc_object_t responseDict = xpc_dictionary_create(NULL, NULL, 0);

    xpc_dictionary_set_int64(responseDict, "type", response.type);

    if (response.data) {
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:response.data requiringSecureCoding:NO error:nil];
        if (data) {
            xpc_dictionary_set_data(responseDict, "data", data.bytes, data.length);
        }
    }

    if (response.errorMessage) {
        xpc_dictionary_set_string(responseDict, "error", response.errorMessage.UTF8String);
    }

    xpc_connection_send_message(connection, responseDict);
    CFRelease((__bridge CFTypeRef)responseDict);
}

- (macwmfxServerResponse *)handleCommand:(macwmfxServerCommand)command withData:(nullable id)data {
    macwmfxServerResponse *response = [[macwmfxServerResponse alloc] init];

    @try {
        switch (command) {
            case macwmfxServerCommandReload:
                [self reloadAllApplications];
                response.type = macwmfxServerResponseTypeSuccess;
                response.data = @{@"message": @"All applications reloaded successfully"};
                break;

            case macwmfxServerCommandStart:
                [self startServer];
                response.type = macwmfxServerResponseTypeSuccess;
                response.data = @{@"message": @"Server started"};
                break;

            case macwmfxServerCommandStop:
                [self stopServer];
                response.type = macwmfxServerResponseTypeSuccess;
                response.data = @{@"message": @"Server stopped"};
                break;

            case macwmfxServerCommandEnableBorders:
                gOutlineConfig.enabled = YES;
                [self updateAllWindows];
                response.type = macwmfxServerResponseTypeSuccess;
                response.data = @{@"message": @"Window borders enabled"};
                break;

            case macwmfxServerCommandDisableBorders:
                gOutlineConfig.enabled = NO;
                [self updateAllWindows];
                response.type = macwmfxServerResponseTypeSuccess;
                response.data = @{@"message": @"Window borders disabled"};
                break;

            case macwmfxServerCommandSetBorderWidth:
                if ([data isKindOfClass:[NSNumber class]]) {
                    gOutlineConfig.width = [data floatValue];
                    [self updateAllWindows];
                    response.type = macwmfxServerResponseTypeSuccess;
                    response.data = @{@"message": [NSString stringWithFormat:@"Border width set to %.1f", [data floatValue]]};
                } else {
                    response.type = macwmfxServerResponseTypeError;
                    response.errorMessage = @"Invalid border width value";
                }
                break;

            case macwmfxServerCommandSetBorderRadius:
                if ([data isKindOfClass:[NSNumber class]]) {
                    gOutlineConfig.cornerRadius = [data floatValue];
                    [self updateAllWindows];
                    response.type = macwmfxServerResponseTypeSuccess;
                    response.data = @{@"message": [NSString stringWithFormat:@"Border radius set to %.1f", [data floatValue]]};
                } else {
                    response.type = macwmfxServerResponseTypeError;
                    response.errorMessage = @"Invalid border radius value";
                }
                break;

            case macwmfxServerCommandEnableResize:
                gWindowSizeConstraintsConfig.enabled = NO;
                [self updateAllWindows];
                response.type = macwmfxServerResponseTypeSuccess;
                response.data = @{@"message": @"Free window resizing enabled"};
                break;

            case macwmfxServerCommandDisableResize:
                gWindowSizeConstraintsConfig.enabled = YES;
                [self updateAllWindows];
                response.type = macwmfxServerResponseTypeSuccess;
                response.data = @{@"message": @"Free window resizing disabled"};
                break;

            case macwmfxServerCommandUpdateConfig:
                if ([data isKindOfClass:[NSDictionary class]]) {
                    [self updateConfiguration:data];
                    response.type = macwmfxServerResponseTypeSuccess;
                    response.data = @{@"message": @"Configuration updated"};
                } else {
                    response.type = macwmfxServerResponseTypeError;
                    response.errorMessage = @"Invalid configuration data";
                }
                break;

            case macwmfxServerCommandGetStatus:
                response.type = macwmfxServerResponseTypeStatus;
                response.data = @{
                    @"running": @(_isRunning),
                    @"clientCount": @(_clientConnections.count),
                    @"config": @{
                        @"bordersEnabled": @(gOutlineConfig.enabled),
                        @"borderWidth": @(gOutlineConfig.width),
                        @"borderRadius": @(gOutlineConfig.cornerRadius),
                        @"resizeEnabled": @(!gWindowSizeConstraintsConfig.enabled)
                    },
                    @"modules": [gmacwmfxServer getAllModuleInfo]
                };
                break;

            case macwmfxServerCommandEnableModule:
                if ([data isKindOfClass:[NSString class]]) {
                    BOOL success = [gmacwmfxServer enableModule:data];
                    response.type = success ? macwmfxServerResponseTypeSuccess : macwmfxServerResponseTypeError;
                    response.data = @{@"message": success ?
                        [NSString stringWithFormat:@"Module %@ enabled", data] :
                        [NSString stringWithFormat:@"Failed to enable module %@", data]};
                } else {
                    response.type = macwmfxServerResponseTypeError;
                    response.errorMessage = @"Invalid module name";
                }
                break;

            case macwmfxServerCommandDisableModule:
                if ([data isKindOfClass:[NSString class]]) {
                    BOOL success = [gmacwmfxServer disableModule:data];
                    response.type = success ? macwmfxServerResponseTypeSuccess : macwmfxServerResponseTypeError;
                    response.data = @{@"message": success ?
                        [NSString stringWithFormat:@"Module %@ disabled", data] :
                        [NSString stringWithFormat:@"Failed to disable module %@", data]};
                } else {
                    response.type = macwmfxServerResponseTypeError;
                    response.errorMessage = @"Invalid module name";
                }
                break;

            case macwmfxServerCommandGetModuleInfo:
                if ([data isKindOfClass:[NSString class]]) {
                    NSDictionary *info = [gmacwmfxServer getModuleInfo:data];
                    if (info) {
                        response.type = macwmfxServerResponseTypeSuccess;
                        response.data = info;
                    } else {
                        response.type = macwmfxServerResponseTypeError;
                        response.errorMessage = [NSString stringWithFormat:@"Module %@ not found", data];
                    }
                } else {
                    response.type = macwmfxServerResponseTypeError;
                    response.errorMessage = @"Invalid module name";
                }
                break;

            case macwmfxServerCommandListModules:
                response.type = macwmfxServerResponseTypeSuccess;
                response.data = @{
                    @"available": [gmacwmfxServer getAvailableModules],
                    @"loaded": [gmacwmfxServer getLoadedModules],
                    @"allInfo": [gmacwmfxServer getAllModuleInfo]
                };
                break;

            default:
                response.type = macwmfxServerResponseTypeError;
                response.errorMessage = @"Unknown command";
                break;
        }
    } @catch (NSException *exception) {
        response.type = macwmfxServerResponseTypeError;
        response.errorMessage = [NSString stringWithFormat:@"Exception: %@", exception.reason];
    }

    return response;
}

- (void)loadConfiguration {
    [[ConfigParser sharedInstance] loadConfig];
    MACWMFX_LOG_INFO(macwmfx_log_server, "Configuration loaded");
}

- (void)reloadConfiguration {
    [self loadConfiguration];
    [self updateAllWindows];
    MACWMFX_LOG_INFO(macwmfx_log_server, "Configuration reloaded");
}

- (void)updateConfiguration:(NSDictionary *)config {
    // Update global config variables based on the provided configuration
    // This would need to be implemented based on your config structure
    MACWMFX_LOG_INFO(macwmfx_log_server, "Configuration updated");
}

- (void)updateAllWindows {
    dispatch_async(dispatch_get_main_queue(), ^{
        for (NSWindow *window in [NSApp windows]) {
            [self updateWindow:window];
        }
    });
}

- (void)updateWindow:(NSWindow *)window {
    // Trigger window update notification
    [[NSDistributedNotificationCenter defaultCenter]
        postNotificationName:@"com.aspauldingcode.macwmfx.updateWindow"
                    object:[NSString stringWithFormat:@"%ld", (long)window.windowNumber]
                  userInfo:nil
        deliverImmediately:YES];
}

- (void)reloadAllApplications {
    MACWMFX_LOG_INFO(macwmfx_log_server, "Reloading all applications...");

    // Store running applications before killing them
    NSArray<NSRunningApplication *> *runningApps = [self getRunningGUIApplications];
    NSMutableArray<NSDictionary *> *appsToRestart = [NSMutableArray array];

    for (NSRunningApplication *app in runningApps) {
        // Skip system apps and our own process
        if ([self shouldSkipApplication:app]) {
            continue;
        }

        NSDictionary *appInfo = @{
            @"bundleIdentifier": app.bundleIdentifier ?: @"",
            @"bundleURL": app.bundleURL ? app.bundleURL.path : @"",
            @"localizedName": app.localizedName ?: @""
        };
        [appsToRestart addObject:appInfo];
        MACWMFX_LOG_INFO(macwmfx_log_server, "Will restart app: %@", app.localizedName);
    }

    // Kill all applications
    [self killAllApplications];

    // Wait for apps to close, then reload config and restart apps
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // Reload configuration
        [self reloadConfiguration];

        // Restart applications
        [self restartApplications:appsToRestart];

        MACWMFX_LOG_INFO(macwmfx_log_server, "All applications reloaded and restarted");
    });
}

- (void)killAllApplications {
    NSArray<NSRunningApplication *> *apps = [self getRunningGUIApplications];

    for (NSRunningApplication *app in apps) {
        if ([self shouldSkipApplication:app]) {
            continue;
        }

        MACWMFX_LOG_INFO(macwmfx_log_server, "Terminating app: %@", app.localizedName);

        // First try to terminate gracefully
        BOOL terminated = [app terminate];

        if (!terminated) {
            // If graceful termination fails, try force termination after a short delay
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                // Check if app is still running by looking it up in the running applications list
                NSArray<NSRunningApplication *> *currentApps = [[NSWorkspace sharedWorkspace] runningApplications];
                BOOL stillRunning = NO;
                for (NSRunningApplication *currentApp in currentApps) {
                    if ([currentApp.bundleIdentifier isEqualToString:app.bundleIdentifier]) {
                        stillRunning = YES;
                        break;
                    }
                }

                if (stillRunning) {
                    MACWMFX_LOG_INFO(macwmfx_log_server, "Force terminating app: %@", app.localizedName);
                    [app forceTerminate];
                }
            });
        }
    }
}

- (NSArray<NSRunningApplication *> *)getRunningGUIApplications {
    NSArray<NSRunningApplication *> *allApps = [[NSWorkspace sharedWorkspace] runningApplications];
    NSMutableArray<NSRunningApplication *> *guiApps = [NSMutableArray array];

    for (NSRunningApplication *app in allApps) {
        // Only include GUI applications (those with AppKit)
        if (app.activationPolicy == NSApplicationActivationPolicyRegular) {
            [guiApps addObject:app];
        }
    }

    return [guiApps copy];
}

- (BOOL)shouldSkipApplication:(NSRunningApplication *)app {
    // Skip system applications and processes that shouldn't be killed
    static NSSet<NSString *> *excludedBundleIds = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        excludedBundleIds = [NSSet setWithArray:@[
            @"com.apple.finder",
            @"com.apple.dock",
            @"com.apple.systemuiserver",
            @"com.apple.WindowManager",
            @"com.apple.loginwindow",
            @"com.apple.systempreferences",
            @"com.apple.ActivityMonitor",
            @"com.apple.Console",
            @"com.apple.Terminal",
            @"com.apple.dt.Xcode",
            @"com.microsoft.VSCode",
            @"com.apple.Safari", // Optional: uncomment if you want to preserve Safari
            // Add other apps you want to preserve during reload
        ]];
    });

    // Skip if no bundle identifier
    if (!app.bundleIdentifier) {
        return YES;
    }

    // Skip excluded applications
    if ([excludedBundleIds containsObject:app.bundleIdentifier]) {
        MACWMFX_LOG_INFO(macwmfx_log_server, "Skipping system app: %@", app.localizedName);
        return YES;
    }

    // Skip if it's our own process or related processes
    if ([app.bundleIdentifier containsString:@"macwmfx"] ||
        [app.bundleIdentifier containsString:@"ammonia"]) {
        return YES;
    }

    return NO;
}

- (void)restartApplications:(NSArray<NSDictionary *> *)appsToRestart {
    MACWMFX_LOG_INFO(macwmfx_log_server, "Restarting %lu applications...", (unsigned long)appsToRestart.count);

    for (NSDictionary *appInfo in appsToRestart) {
        NSString *bundleIdentifier = appInfo[@"bundleIdentifier"];
        NSString *bundlePath = appInfo[@"bundleURL"];
        NSString *appName = appInfo[@"localizedName"];

        if (bundleIdentifier.length > 0) {
            // Try to launch by bundle identifier first
            BOOL launched = [[NSWorkspace sharedWorkspace] launchAppWithBundleIdentifier:bundleIdentifier
                                                                                  options:NSWorkspaceLaunchDefault
                                                           additionalEventParamDescriptor:nil
                                                                         launchIdentifier:NULL];

            if (launched) {
                MACWMFX_LOG_INFO(macwmfx_log_server, "Restarted app: %@", appName);
            } else if (bundlePath.length > 0) {
                // If bundle identifier launch fails, try launching by path
                NSURL *appURL = [NSURL fileURLWithPath:bundlePath];
                NSError *error = nil;
                NSRunningApplication *launchedApp = [[NSWorkspace sharedWorkspace] launchApplicationAtURL:appURL
                                                                                                   options:NSWorkspaceLaunchDefault
                                                                                             configuration:@{}
                                                                                                     error:&error];

                if (launchedApp) {
                    MACWMFX_LOG_INFO(macwmfx_log_server, "Restarted app via path: %@", appName);
                    launched = YES;
                } else {
                    MACWMFX_LOG_ERROR(macwmfx_log_server, "Failed to restart app %@: %@", appName, error.localizedDescription);
                }
            } else {
                MACWMFX_LOG_ERROR(macwmfx_log_server, "Could not restart app %@ - no valid bundle identifier or path", appName);
            }
        }

        // Small delay between app launches to avoid overwhelming the system
        usleep(200000); // 200ms
    }
}

- (NSArray<NSRunningApplication *> *)getRunningApplications {
    return [self getRunningGUIApplications];
}

#pragma mark - Module Management

- (BOOL)enableModule:(NSString *)moduleName {
    return [gmacwmfxServer enableModule:moduleName];
}

- (BOOL)disableModule:(NSString *)moduleName {
    return [gmacwmfxServer disableModule:moduleName];
}

- (BOOL)isModuleEnabled:(NSString *)moduleName {
    return [gmacwmfxServer isModuleEnabled:moduleName];
}

- (NSDictionary *)getModuleInfo:(NSString *)moduleName {
    return [gmacwmfxServer getModuleInfo:moduleName];
}

- (NSArray<NSString *> *)getAvailableModules {
    return [gmacwmfxServer getAvailableModules];
}

- (NSArray<NSString *> *)getLoadedModules {
    return [gmacwmfxServer getLoadedModules];
}

- (NSDictionary *)getAllModuleInfo {
    return [gmacwmfxServer getAllModuleInfo];
}

@end

@implementation ContextualMenuButton
- (void)displayAssociatedMenu:(id)sender {
    NSRect buttonBounds = [self bounds];
    NSPoint location = NSMakePoint(NSMinX(buttonBounds), NSMinY(buttonBounds) + kRibbonHeight);
    DisplayMenuAsContextual(self.associatedMenu, self, location);
}
@end

// Unified LoadFunction that combines all functionality
__attribute__((visibility("default"))) void LoadFunction(void *interceptor) {
    // Initialize logging system first
    macwmfx_logging_init();

    MACWMFX_LOG_INFO(macwmfx_log_server, "Unified LoadFunction called - initializing all components");

    // 1. Initialize main macwmfx orchestrator
    [[macwmfx sharedInstance] start];
    MACWMFX_LOG_INFO(macwmfx_log_server, "Main orchestrator started");

    // 2. Initialize ribbon bar functionality
    void *hooking = dlopen("/private/var/ammonia/core/fridagum.dylib", RTLD_NOW | RTLD_GLOBAL);
    if (hooking) {
        GumInterceptorReplaceFunc = (GumInterceptorReplaceFuncType)(dlsym(hooking, "gum_interceptor_replace"));
        GumInterceptorBeginTransactionFunc = (GumInterceptorBeginTransactionFuncType)(dlsym(hooking, "gum_interceptor_begin_transaction"));
        GumInterceptorEndTransactionFunc = (GumInterceptorEndTransactionFuncType)(dlsym(hooking, "gum_interceptor_end_transaction"));

        gHook = interceptor;

        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"NSEnableAppKitMenus"];

        // Setup ribbon bar hooks
        struct Hook {
            const char *className;
            SEL originalSelector;
            SEL swizzledSelector;
            IMP implementation;
            void *originalMethodStorage;
            BOOL isClassMethod;
        } hooks[] = {
            {"NSWindow", @selector(toolbarStyle), sel_registerName("$ForceTitlebar"), (IMP)ForceTitlebar, &_ForceTitlebarOld, NO},
            {"NSThemeFrame", @selector(titlebarView), sel_registerName("$AddViews"), (IMP)TitlebarContainerView, &_TitlebarContainerViewOld, NO}
        };

        for (size_t i = 0; i < sizeof(hooks) / sizeof(hooks[0]); i++) {
            Class class = NSClassFromString(@(hooks[i].className));
            AddHook(class, hooks[i].originalSelector, hooks[i].swizzledSelector, hooks[i].implementation, hooks[i].originalMethodStorage, hooks[i].isClassMethod);
        }
        MACWMFX_LOG_INFO(macwmfx_log_server, "Ribbon bar functionality initialized");
    } else {
        MACWMFX_LOG_WARNING(macwmfx_log_server, "Warning: Could not load Frida gum library for ribbon bar");
    }

    // 3. Initialize background server
    gmacwmfxServer = [macwmfxServer sharedServer];
    [gmacwmfxServer startServer];
    MACWMFX_LOG_INFO(macwmfx_log_server, "Background server started");

    MACWMFX_LOG_INFO(macwmfx_log_server, "All components initialized successfully");
}
