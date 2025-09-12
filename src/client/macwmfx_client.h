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
typedef void (^macwmfxClientCompletionBlock)(macwmfxServerResponse * _Nullable response, NSError * _Nullable error);

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
- (void)startServerWithCompletion:(nullable macwmfxClientCompletionBlock)completion;
- (void)stopServerWithCompletion:(nullable macwmfxClientCompletionBlock)completion;
- (void)enableBordersWithCompletion:(nullable macwmfxClientCompletionBlock)completion;
- (void)disableBordersWithCompletion:(nullable macwmfxClientCompletionBlock)completion;
- (void)setBorderWidth:(float)width completion:(nullable macwmfxClientCompletionBlock)completion;
- (void)setBorderRadius:(float)radius completion:(nullable macwmfxClientCompletionBlock)completion;
- (void)enableResizeWithCompletion:(nullable macwmfxClientCompletionBlock)completion;
- (void)disableResizeWithCompletion:(nullable macwmfxClientCompletionBlock)completion;
- (void)getStatusWithCompletion:(nullable macwmfxClientCompletionBlock)completion;

// Module management commands
- (void)enableModule:(NSString *)moduleName completion:(nullable macwmfxClientCompletionBlock)completion;
- (void)disableModule:(NSString *)moduleName completion:(nullable macwmfxClientCompletionBlock)completion;
- (void)getModuleInfo:(NSString *)moduleName completion:(nullable macwmfxClientCompletionBlock)completion;
- (void)listModulesWithCompletion:(nullable macwmfxClientCompletionBlock)completion;

// Generic command method
- (void)sendCommand:(NSInteger)command withData:(nullable id)data completion:(nullable macwmfxClientCompletionBlock)completion;

@end

NS_ASSUME_NONNULL_END
