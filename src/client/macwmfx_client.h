//
//  macwmfx_client.h
//  macwmfx
//
//  Created by Alex "aspauldingcode" on 01/09/25.
//  Copyright (c) 2025 Alex "aspauldingcode". All rights reserved.
//

#import <Foundation/Foundation.h>
#import <xpc/xpc.h>

NS_ASSUME_NONNULL_BEGIN

// Forward declarations
@class macwmfxServerResponse;

// Client completion block
typedef void (^macwmfxClientCompletionBlock)(
    macwmfxServerResponse *_Nullable response, NSError *_Nullable error);

// Client class for communicating with the macwmfx server
@interface macwmfxClient : NSObject

// Singleton access
+ (instancetype)sharedClient;

// Connection management
- (void)connectWithCompletion:(nullable macwmfxClientCompletionBlock)completion;
- (void)disconnect;
- (BOOL)isConnected;

// Server commands
- (void)reloadWithCompletion:(nullable macwmfxClientCompletionBlock)completion;
- (void)startServerWithCompletion:
    (nullable macwmfxClientCompletionBlock)completion;
- (void)stopServerWithCompletion:
    (nullable macwmfxClientCompletionBlock)completion;
- (void)getStatusWithCompletion:
    (nullable macwmfxClientCompletionBlock)completion;

@end

NS_ASSUME_NONNULL_END
