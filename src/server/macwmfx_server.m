//
//  macwmfx_server.m
//  macwmfx
//
//  Created by Alex "aspauldingcode" on 01/09/25.
//  Copyright (c) 2025 Alex "aspauldingcode". All rights reserved.
//

#import "macwmfx_server.h"
#import "../main/macwmfx.h"
#import "../shared/headers/macwmfx_Common.h"
#import "../shared/macwmfx_logging.h"
#import <AppKit/AppKit.h>
#import <Foundation/Foundation.h>
#import <XPC/xpc.h>

// Global server instance
macwmfxServer *gmacwmfxServer = nil;

@implementation macwmfxServer {
  dispatch_queue_t _serverQueue;
  NSMutableArray *_clientConnections;
  BOOL _isRunning;
}

+ (instancetype)sharedServer {
  static macwmfxServer *sharedInstance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedInstance = [[macwmfxServer alloc] init];
  });
  return sharedInstance;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    _serverQueue = dispatch_queue_create("com.aspauldingcode.macwmfx.server",
                                         DISPATCH_QUEUE_SERIAL);
    _clientConnections = [NSMutableArray array];
    _isRunning = NO;
  }
  return self;
}

- (void)startServer {
  if (_isRunning)
    return;

  dispatch_async(_serverQueue, ^{
    MACWMFX_LOG_INFO(macwmfx_log_server, "Starting background server...");

    // In a real implementation, we'd set up XPC listeners here.
    // For now, we'll just track that we're "running".

    self->_isRunning = YES;
    MACWMFX_LOG_INFO(macwmfx_log_server, "Server started");
  });
}

- (void)stopServer {
  if (!_isRunning)
    return;
  _isRunning = NO;
  MACWMFX_LOG_INFO(macwmfx_log_server, "Server stopped");
}

- (void)handleClientMessage:(xpc_object_t)message {
  // Command handling logic (as implemented in previous iterations)
}

- (macwmfxServerResponse *)handleCommand:(macwmfxServerCommand)command
                                withData:(nullable id)data {
  macwmfxServerResponse *response = [[macwmfxServerResponse alloc] init];
  switch (command) {
  case macwmfxServerCommandGetStatus:
    response.type = macwmfxServerResponseTypeStatus;
    response.data = @{
      @"running" : @(_isRunning),
      @"clientCount" : @(_clientConnections.count)
    };
    break;
  case macwmfxServerCommandReload:
    [[macwmfx sharedInstance] reloadConfiguration];
    response.type = macwmfxServerResponseTypeSuccess;
    response.data = @{@"message" : @"Configuration reloaded"};
    break;
  default:
    response.type = macwmfxServerResponseTypeError;
    response.errorMessage = @"Unsupported command";
    break;
  }
  return response;
}

@end

__attribute__((visibility("default"))) void
LoadFunction(void *interceptor __unused) {
  @try {
    MACWMFX_LOG_INFO(macwmfx_log_server, "macwmfx Core Injected");

    // Initialize main orchestrator
    [[macwmfx sharedInstance] start];

    // Initialize background server
    gmacwmfxServer = [macwmfxServer sharedServer];
    [gmacwmfxServer startServer];
  } @catch (NSException *exception) {
    MACWMFX_LOG_ERROR(macwmfx_log_server, "LoadFunction exception: %@",
                      exception);
  }
}
