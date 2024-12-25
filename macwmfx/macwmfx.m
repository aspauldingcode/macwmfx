//
//  macwmfx.m
//  macwmfx
//
//  Created by Alex "aspauldingcode" on 11/13/24.
//  Copyright (c) 2024 Alex "aspauldingcode". All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MacWMFX : NSObject

- (void)loadFeaturesFromConfig;

@end

@implementation MacWMFX

- (void)loadFeaturesFromConfig {
    NSString *configPath = [NSHomeDirectory() stringByAppendingPathComponent:@".config/macwmfx/config"];
    NSData *data = [NSData dataWithContentsOfFile:configPath];
    if (data) {
        NSError *error = nil;
        NSDictionary *config = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        if (!error && config != nil) {
            // Load features based on config
            // Example: if ([config[@"DisableTrafficLights"] boolValue]) { [self loadDisableTrafficLights]; }
            NSLog(@"Config loaded successfully: %@", config);
        } else {
            NSLog(@"Error reading config: %@", error);
        }
    } else {
        NSLog(@"Config file not found at path: %@", configPath);
    }
}

@end
