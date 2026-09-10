//
//  macwmfx_client.m
//  macwmfx
//
//  Created by Alex "aspauldingcode" on 01/09/25.
//  Copyright (c) 2025 Alex "aspauldingcode". All rights reserved.
//

#import "macwmfx_client.h"
#import "../server/macwmfx_server.h"
#import "../shared/macwmfx_logging.h"

static const char *kmacwmfxServiceName = "com.aspauldingcode.macwmfx.server";

@implementation macwmfxClient {
  xpc_connection_t _connection;
  dispatch_queue_t _clientQueue;
  BOOL _isConnected;
  macwmfxClientCompletionBlock _pendingConnectCompletion;
  NSMutableDictionary<NSNumber *, macwmfxClientCompletionBlock>
      *_pendingRequests;
  uint64_t _nextMessageID;
}

+ (instancetype)sharedClient {
  static macwmfxClient *sharedInstance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedInstance = [[self alloc] init];
  });
  return sharedInstance;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    macwmfx_logging_init();
    _clientQueue = dispatch_queue_create("com.aspauldingcode.macwmfx.client",
                                         DISPATCH_QUEUE_SERIAL);
    _isConnected = NO;
    _pendingRequests = [NSMutableDictionary dictionary];
    _nextMessageID = 1;
    MACWMFX_LOG_INFO(macwmfx_log_client, "Client initialized");
  }
  return self;
}

- (void)connectWithCompletion:
    (nullable macwmfxClientCompletionBlock)completion {
  if (_isConnected) {
    if (completion)
      completion(nil, nil);
    return;
  }

  dispatch_async(_clientQueue, ^{
    self->_connection = xpc_connection_create_mach_service(
        kmacwmfxServiceName, self->_clientQueue, 0);
    if (!self->_connection) {
      if (completion)
        completion(nil, [NSError errorWithDomain:@"macwmfx"
                                            code:1
                                        userInfo:nil]);
      return;
    }

    xpc_connection_set_event_handler(self->_connection, ^(xpc_object_t event) {
      [self handleXPCEvent:event];
    });

    xpc_connection_activate(self->_connection);
    self->_isConnected = YES;
    if (completion)
      completion(nil, nil);
  });
}

- (void)disconnect {
  if (!_isConnected)
    return;
  dispatch_async(_clientQueue, ^{
    if (self->_connection) {
      xpc_connection_cancel(self->_connection);
      self->_connection = NULL;
    }
    self->_isConnected = NO;
  });
}

- (BOOL)isConnected {
  return _isConnected;
}

- (void)handleXPCEvent:(xpc_object_t)event {
  if (xpc_get_type(event) == XPC_TYPE_DICTIONARY) {
    [self handleServerResponse:event];
  } else if (event == XPC_ERROR_CONNECTION_INVALID ||
             event == XPC_ERROR_CONNECTION_INTERRUPTED) {
    _isConnected = NO;
  }
}

- (void)handleServerResponse:(xpc_object_t)response {
  uint64_t messageID = xpc_dictionary_get_uint64(response, "messageID");
  int64_t typeValue = xpc_dictionary_get_int64(response, "type");

  macwmfxServerResponse *serverResponse = [[macwmfxServerResponse alloc] init];
  serverResponse.type = (macwmfxServerResponseType)typeValue;

  const char *error = xpc_dictionary_get_string(response, "error");
  if (error)
    serverResponse.errorMessage = @(error);

  dispatch_async(_clientQueue, ^{
    macwmfxClientCompletionBlock completion =
        self->_pendingRequests[@(messageID)];
    if (completion) {
      completion(serverResponse, nil);
      [self->_pendingRequests removeObjectForKey:@(messageID)];
    }
  });
}

- (void)sendCommand:(macwmfxServerCommand)command
           withData:(nullable id)data
         completion:(nullable macwmfxClientCompletionBlock)completion {
  if (!_isConnected) {
    if (completion)
      completion(nil, [NSError errorWithDomain:@"macwmfx" code:3 userInfo:nil]);
    return;
  }

  dispatch_async(_clientQueue, ^{
    uint64_t messageID = self->_nextMessageID++;
    if (completion)
      self->_pendingRequests[@(messageID)] = [completion copy];

    xpc_object_t message = xpc_dictionary_create(NULL, NULL, 0);
    xpc_dictionary_set_int64(message, "command", command);
    xpc_dictionary_set_uint64(message, "messageID", messageID);

    xpc_connection_send_message(self->_connection, message);
  });
}

- (void)reloadWithCompletion:(nullable macwmfxClientCompletionBlock)completion {
  [self sendCommand:macwmfxServerCommandReload
           withData:nil
         completion:completion];
}

- (void)startServerWithCompletion:
    (nullable macwmfxClientCompletionBlock)completion {
  [self sendCommand:macwmfxServerCommandStart
           withData:nil
         completion:completion];
}

- (void)stopServerWithCompletion:
    (nullable macwmfxClientCompletionBlock)completion {
  [self sendCommand:macwmfxServerCommandStop
           withData:nil
         completion:completion];
}

- (void)getStatusWithCompletion:
    (nullable macwmfxClientCompletionBlock)completion {
  [self sendCommand:macwmfxServerCommandGetStatus
           withData:nil
         completion:completion];
}

@end
