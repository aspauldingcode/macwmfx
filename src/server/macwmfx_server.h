//
//  macwmfx_server.h
//  macwmfx
//
//  Created by Alex "aspauldingcode" on 01/09/25.
//  Copyright (c) 2025 Alex "aspauldingcode". All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <xpc/xpc.h>
#import <dispatch/dispatch.h>

NS_ASSUME_NONNULL_BEGIN

// Server command types
typedef NS_ENUM(NSInteger, macwmfxServerCommand) {
    macwmfxServerCommandReload = 1,
    macwmfxServerCommandStart = 2,
    macwmfxServerCommandStop = 3,
    macwmfxServerCommandEnableBorders = 4,
    macwmfxServerCommandDisableBorders = 5,
    macwmfxServerCommandSetBorderWidth = 6,
    macwmfxServerCommandSetBorderRadius = 7,
    macwmfxServerCommandEnableResize = 8,
    macwmfxServerCommandDisableResize = 9,
    macwmfxServerCommandUpdateConfig = 10,
    macwmfxServerCommandGetStatus = 11,
    macwmfxServerCommandEnableModule = 12,
    macwmfxServerCommandDisableModule = 13,
    macwmfxServerCommandGetModuleInfo = 14,
    macwmfxServerCommandListModules = 15
};

// Server response types
typedef NS_ENUM(NSInteger, macwmfxServerResponseType) {
    macwmfxServerResponseTypeSuccess = 1,
    macwmfxServerResponseTypeError = 2,
    macwmfxServerResponseTypeStatus = 3
};

// Server message structure
@interface macwmfxServerMessage : NSObject
@property (nonatomic, assign) macwmfxServerCommand command;
@property (nonatomic, strong, nullable) id data;
@property (nonatomic, strong, nullable) NSString *errorMessage;
@end

// Server response structure
@interface macwmfxServerResponse : NSObject
@property (nonatomic, assign) macwmfxServerResponseType type;
@property (nonatomic, strong, nullable) id data;
@property (nonatomic, strong, nullable) NSString *errorMessage;
@end

// Main server class
@interface macwmfxServer : NSObject

// Singleton access
+ (instancetype)sharedServer;

// Lifecycle management
- (void)startServer;
- (void)stopServer;
- (BOOL)isServerRunning;

// Configuration management
- (void)loadConfiguration;
- (void)reloadConfiguration;
- (void)updateConfiguration:(NSDictionary *)config;

// Window management
- (void)updateAllWindows;
- (void)updateWindow:(NSWindow *)window;

// App lifecycle management
- (void)reloadAllApplications;
- (void)killAllApplications;
- (NSArray<NSRunningApplication *> *)getRunningApplications;
- (NSArray<NSRunningApplication *> *)getRunningGUIApplications;
- (BOOL)shouldSkipApplication:(NSRunningApplication *)app;
- (void)restartApplications:(NSArray<NSDictionary *> *)appsToRestart;

// Command handling
- (macwmfxServerResponse *)handleCommand:(macwmfxServerCommand)command withData:(nullable id)data;

// Module management
- (BOOL)enableModule:(NSString *)moduleName;
- (BOOL)disableModule:(NSString *)moduleName;
- (BOOL)isModuleEnabled:(NSString *)moduleName;
- (NSDictionary *)getModuleInfo:(NSString *)moduleName;
- (NSArray<NSString *> *)getAvailableModules;
- (NSArray<NSString *> *)getLoadedModules;
- (NSDictionary *)getAllModuleInfo;

// XPC connection management
- (void)handleClientConnection:(xpc_connection_t)connection;
- (void)sendResponse:(macwmfxServerResponse *)response toConnection:(xpc_connection_t)connection;

@end

// Global server instance
extern macwmfxServer *gmacwmfxServer;

NS_ASSUME_NONNULL_END
