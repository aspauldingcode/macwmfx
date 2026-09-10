//
//  macwmfx_server.h
//  macwmfx
//
//  Created by Alex "aspauldingcode" on 01/09/25.
//  Copyright (c) 2025 Alex "aspauldingcode". All rights reserved.
//

#import <AppKit/AppKit.h>
#import <Foundation/Foundation.h>
#import <dispatch/dispatch.h>
#import <xpc/xpc.h>

NS_ASSUME_NONNULL_BEGIN

// Server command types
typedef NS_ENUM(NSInteger, macwmfxServerCommand) {
  macwmfxServerCommandReload = 1,
  macwmfxServerCommandStart = 2,
  macwmfxServerCommandStop = 3,
  macwmfxServerCommandGetStatus = 11
};

// Server response types
typedef NS_ENUM(NSInteger, macwmfxServerResponseType) {
  macwmfxServerResponseTypeSuccess = 1,
  macwmfxServerResponseTypeError = 2,
  macwmfxServerResponseTypeStatus = 3
};

// Server message structure
@interface macwmfxServerMessage : NSObject <NSSecureCoding>
@property(nonatomic, assign) macwmfxServerCommand command;
@property(nonatomic, strong, nullable) id data;
@end

// Server response structure
@interface macwmfxServerResponse : NSObject <NSSecureCoding>
@property(nonatomic, assign) macwmfxServerResponseType type;
@property(nonatomic, strong, nullable) id data;
@property(nonatomic, strong, nullable) NSString *errorMessage;
@end

// Main server class
@interface macwmfxServer : NSObject

// Singleton access
+ (instancetype)sharedServer;

// Lifecycle management
- (void)startServer;
- (void)stopServer;

// Command handling
- (macwmfxServerResponse *)handleCommand:(macwmfxServerCommand)command
                                withData:(nullable id)data;

@end

// Global server instance
extern macwmfxServer *_Nullable gmacwmfxServer;

NS_ASSUME_NONNULL_END
