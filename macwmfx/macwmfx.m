//
//  macwmfx.m
//  macwmfx
//
//  Created by Alex "aspauldingcode" on 11/13/24.
//  Copyright (c) 2024 Alex "aspauldingcode". All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "headers/macwmfx_globals.h"
#import <sys/mman.h>
#import <fcntl.h>
#import <unistd.h>

// Shared memory implementation
SharedMemory* getSharedMemory(void) {
    int fd = open(SHARED_MEMORY_PATH, O_RDWR | O_CREAT, 0666);
    if (fd == -1) {
        NSLog(@"Failed to open shared memory");
        return NULL;
    }
    
    // Set the size of the file
    ftruncate(fd, sizeof(SharedMemory));
    
    // Map the file into memory
    SharedMemory* shared = mmap(NULL, sizeof(SharedMemory), PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
    close(fd);
    
    if (shared == MAP_FAILED) {
        NSLog(@"Failed to map shared memory");
        return NULL;
    }
    
    return shared;
}

@interface MacWMFX : NSObject

+ (instancetype)sharedInstance;
- (void)startListeningForUpdates;
- (void)handleWindowUpdate:(NSNotification *)notification;

@end

@implementation MacWMFX

+ (void)load {
    // Check if we're running from CLI by looking at the process name
    NSString *processName = [[NSProcessInfo processInfo] processName];
    if ([processName isEqualToString:@"macwmfx"]) {
        gRunningFromCLI = YES;
        return;  // Skip loading config if running from CLI
    }
    
    // Initialize the singleton and load config
    MacWMFX *instance = [self sharedInstance];
    [[ConfigParser sharedInstance] loadConfig];
    [instance startListeningForUpdates];
}

+ (instancetype)sharedInstance {
    static MacWMFX *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[MacWMFX alloc] init];
    });
    return sharedInstance;
}

- (void)startListeningForUpdates {
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self
                                                      selector:@selector(handleWindowUpdate:)
                                                          name:@"com.macwmfx.updateWindow"
                                                        object:nil];
}

- (void)handleWindowUpdate:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        // Get the window number from the notification
        NSString *windowNumberStr = notification.object;
        if (!windowNumberStr) return;
        
        NSInteger windowNumber = [windowNumberStr integerValue];
        NSWindow *window = [NSApp windowWithWindowNumber:windowNumber];
        
        if (window && [window respondsToSelector:@selector(updateBorderStyle)]) {
            [window performSelector:@selector(updateBorderStyle)];
            [window display];
        }
    });
}

@end
