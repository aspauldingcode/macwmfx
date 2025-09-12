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

// XPC service name
static const char *kmacwmfxServiceName = "com.aspauldingcode.macwmfx.server";

@implementation macwmfxClient {
    xpc_connection_t _connection;
    dispatch_queue_t _clientQueue;
    BOOL _isConnected;
    macwmfxClientCompletionBlock _pendingConnectCompletion;
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
        // Initialize logging system
        macwmfx_logging_init();

        _clientQueue = dispatch_queue_create("com.aspauldingcode.macwmfx.client", DISPATCH_QUEUE_SERIAL);
        _isConnected = NO;

        MACWMFX_LOG_INFO(macwmfx_log_client, "macwmfx client initialized");
    }
    return self;
}

- (void)connectWithCompletion:(nullable macwmfxClientCompletionBlock)completion {
    if (_isConnected) {
        if (completion) {
            completion(nil, [NSError errorWithDomain:@"com.aspauldingcode.macwmfx.client" code:1 userInfo:@{NSLocalizedDescriptionKey: @"Already connected"}]);
        }
        return;
    }

    dispatch_async(_clientQueue, ^{
        // Create XPC connection
        self->_connection = xpc_connection_create_mach_service(kmacwmfxServiceName, self->_clientQueue, 0);

        if (!self->_connection) {
            if (completion) {
                NSError *error = [NSError errorWithDomain:@"com.aspauldingcode.macwmfx.client" code:2 userInfo:@{NSLocalizedDescriptionKey: @"Failed to create XPC connection - service not available"}];
                completion(nil, error);
            }
            return;
        }

        // Store the completion block for error handling
        self->_pendingConnectCompletion = [completion copy];

        // Set up event handler
        xpc_connection_set_event_handler(self->_connection, ^(xpc_object_t event) {
            [self handleXPCEvent:event];
        });

        // Activate the connection
        xpc_connection_activate(self->_connection);

        // If we get here, assume connection is in progress; completion will be called on first event or error
        self->_isConnected = YES;
        if (completion) {
            // Call completion optimistically, but if an error event comes in, we'll call it again with error
            completion(nil, nil);
        }
    });
}

- (void)disconnect {
    if (!_isConnected) {
        return;
    }

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
    xpc_type_t type = xpc_get_type(event);

    if (type == XPC_TYPE_DICTIONARY) {
        [self handleServerResponse:event];
    } else if (type == XPC_TYPE_ERROR) {
        _isConnected = NO;
        NSString *errMsg = @"Unknown XPC error";
        if (event == XPC_ERROR_CONNECTION_INTERRUPTED) {
            errMsg = @"XPC connection interrupted";
        } else if (event == XPC_ERROR_CONNECTION_INVALID) {
            errMsg = @"XPC connection invalid (server not running)";
        }
        MACWMFX_LOG_ERROR(macwmfx_log_client, "%s", [errMsg UTF8String]);
        if (_pendingConnectCompletion) {
            NSError *error = [NSError errorWithDomain:@"com.aspauldingcode.macwmfx.client"
                                                 code:4
                                             userInfo:@{NSLocalizedDescriptionKey: errMsg}];
            _pendingConnectCompletion(nil, error);
            _pendingConnectCompletion = nil;
        }
    }
}

- (void)handleServerResponse:(xpc_object_t)response {
    // Parse response
    int64_t typeValue = xpc_dictionary_get_int64(response, "type");
    macwmfxServerResponse *serverResponse = [[macwmfxServerResponse alloc] init];
    serverResponse.type = (macwmfxServerResponseType)typeValue;

    // Extract data
    xpc_object_t dataObject = xpc_dictionary_get_value(response, "data");
    if (dataObject && xpc_get_type(dataObject) == XPC_TYPE_DATA) {
        size_t dataSize = xpc_data_get_length(dataObject);
        const void *dataBytes = xpc_data_get_bytes_ptr(dataObject);
        if (dataSize > 0 && dataBytes) {
            serverResponse.data = [NSKeyedUnarchiver unarchivedObjectOfClass:[NSObject class] fromData:[NSData dataWithBytes:dataBytes length:dataSize] error:nil];
        }
    }

    // Extract error message
    const char *errorString = xpc_dictionary_get_string(response, "error");
    if (errorString) {
        serverResponse.errorMessage = @(errorString);
    }

    // Handle the response (this would typically be passed to a completion block)
    MACWMFX_LOG_INFO(macwmfx_log_client, "Received server response: type=%ld, data=%@, error=%@",
          (long)serverResponse.type, serverResponse.data, serverResponse.errorMessage);
}

- (void)sendCommand:(NSInteger)command withData:(nullable id)data completion:(nullable macwmfxClientCompletionBlock)completion {
    if (!_isConnected) {
        if (completion) {
            NSError *error = [NSError errorWithDomain:@"com.aspauldingcode.macwmfx.client" code:3 userInfo:@{NSLocalizedDescriptionKey: @"Not connected to server"}];
            completion(nil, error);
        }
        return;
    }

    dispatch_async(_clientQueue, ^{
        // Create message
        xpc_object_t message = xpc_dictionary_create(NULL, NULL, 0);
        xpc_dictionary_set_int64(message, "command", command);

        // Add data if provided
        if (data) {
            NSData *archivedData = [NSKeyedArchiver archivedDataWithRootObject:data requiringSecureCoding:NO error:nil];
            if (archivedData) {
                xpc_dictionary_set_data(message, "data", archivedData.bytes, archivedData.length);
            }
        }

        // Send message
        xpc_connection_send_message(self->_connection, message);

        // For now, we'll just log the command
        // In a real implementation, you'd store the completion block and call it when the response arrives
        MACWMFX_LOG_DEBUG(macwmfx_log_client, "Sent command: %ld", (long)command);

        if (completion) {
            // For simplicity, we'll call completion immediately
            // In a real implementation, this would be called when the response arrives
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                macwmfxServerResponse *response = [[macwmfxServerResponse alloc] init];
                response.type = macwmfxServerResponseTypeSuccess;
                response.data = @{@"message": @"Command sent successfully"};
                completion(response, nil);
            });
        }
    });
}

#pragma mark - Convenience Methods

- (void)reloadWithCompletion:(nullable macwmfxClientCompletionBlock)completion {
    [self sendCommand:macwmfxServerCommandReload withData:nil completion:completion];
}

- (void)startServerWithCompletion:(nullable macwmfxClientCompletionBlock)completion {
    [self sendCommand:macwmfxServerCommandStart withData:nil completion:completion];
}

- (void)stopServerWithCompletion:(nullable macwmfxClientCompletionBlock)completion {
    [self sendCommand:macwmfxServerCommandStop withData:nil completion:completion];
}

- (void)enableBordersWithCompletion:(nullable macwmfxClientCompletionBlock)completion {
    [self sendCommand:macwmfxServerCommandEnableBorders withData:nil completion:completion];
}

- (void)disableBordersWithCompletion:(nullable macwmfxClientCompletionBlock)completion {
    [self sendCommand:macwmfxServerCommandDisableBorders withData:nil completion:completion];
}

- (void)setBorderWidth:(float)width completion:(nullable macwmfxClientCompletionBlock)completion {
    [self sendCommand:macwmfxServerCommandSetBorderWidth withData:@(width) completion:completion];
}

- (void)setBorderRadius:(float)radius completion:(nullable macwmfxClientCompletionBlock)completion {
    [self sendCommand:macwmfxServerCommandSetBorderRadius withData:@(radius) completion:completion];
}

- (void)enableResizeWithCompletion:(nullable macwmfxClientCompletionBlock)completion {
    [self sendCommand:macwmfxServerCommandEnableResize withData:nil completion:completion];
}

- (void)disableResizeWithCompletion:(nullable macwmfxClientCompletionBlock)completion {
    [self sendCommand:macwmfxServerCommandDisableResize withData:nil completion:completion];
}

- (void)getStatusWithCompletion:(nullable macwmfxClientCompletionBlock)completion {
    [self sendCommand:macwmfxServerCommandGetStatus withData:nil completion:completion];
}

#pragma mark - Module Management Methods

- (void)enableModule:(NSString *)moduleName completion:(nullable macwmfxClientCompletionBlock)completion {
    [self sendCommand:macwmfxServerCommandEnableModule withData:moduleName completion:completion];
}

- (void)disableModule:(NSString *)moduleName completion:(nullable macwmfxClientCompletionBlock)completion {
    [self sendCommand:macwmfxServerCommandDisableModule withData:moduleName completion:completion];
}

- (void)getModuleInfo:(NSString *)moduleName completion:(nullable macwmfxClientCompletionBlock)completion {
    [self sendCommand:macwmfxServerCommandGetModuleInfo withData:moduleName completion:completion];
}

- (void)listModulesWithCompletion:(nullable macwmfxClientCompletionBlock)completion {
    [self sendCommand:macwmfxServerCommandListModules withData:nil completion:completion];
}

@end
