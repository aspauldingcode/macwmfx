#import <AppKit/AppKit.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Apple Sharpener - Main orchestrator
 */
@interface macwmfx : NSObject

+ (instancetype)sharedInstance;

@property(nonatomic, assign, readonly) BOOL isRunning;

- (void)start;
- (void)stop;

- (void)loadConfiguration;
- (void)reloadConfiguration;

@end

NS_ASSUME_NONNULL_END
