//
//  CLITool.m
//  macwmfx
//
//  Created by Alex "aspauldingcode" on 11/13/24.
//  Copyright (c) 2024 Alex "aspauldingcode". All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "headers/macwmfx_globals.h"
#import "headers/configParser.h"  // Add this line

// Function to update all windows
void updateAllWindows(void) {
    // Get all running applications
    NSArray *apps = [[NSWorkspace sharedWorkspace] runningApplications];
    
    // Iterate through each application
    for (NSRunningApplication *app in apps) {
        if (app.activationPolicy == NSApplicationActivationPolicyRegular) {
            pid_t pid = app.processIdentifier;
            // Use CGWindowListCopyWindowInfo to get windows for this app
            CFArrayRef windowList = CGWindowListCopyWindowInfo(
                kCGWindowListOptionOnScreenOnly | kCGWindowListExcludeDesktopElements,
                kCGNullWindowID);
            
            if (windowList) {
                NSArray *windows = CFBridgingRelease(windowList);
                for (NSDictionary *windowInfo in windows) {
                    NSNumber *windowPid = windowInfo[(id)kCGWindowOwnerPID];
                    if (windowPid.intValue == pid) {
                        // Post a notification to update this window
                        [[NSDistributedNotificationCenter defaultCenter]
                            postNotificationName:@"com.macwmfx.updateWindow"
                                        object:[windowInfo[(id)kCGWindowNumber] stringValue]
                                      userInfo:nil
                            deliverImmediately:YES];
                    }
                }
            }
        }
    }
}

void observeLogs() {
    NSString *command = @"log stream --predicate 'process == \"macwmfx\"'";
    FILE *pipe = popen([command UTF8String], "r");
    if (!pipe) {
        NSLog(@"Error: Could not open pipe for log stream");
        return;
    }

    char buffer[1024];
    while (fgets(buffer, sizeof(buffer), pipe) != NULL) {
        printf("%s", buffer);
        fflush(stdout);
    }
    pclose(pipe);
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // Initialize config parser
        [[ConfigParser sharedInstance] loadConfig];
        
        // Check if we have at least one argument
        if (argc < 2) {
            printf("Usage: %s [--observe-logs]\n", argv[0]);
            return 1;
        }

        NSString *arg = [NSString stringWithUTF8String:argv[1]];
        if ([arg isEqualToString:@"--observe-logs"]) {
            printf("Observing macwmfx logs...\n");
            observeLogs();
            return 0;
        }

        // Modify configuration values
        if ([arg isEqualToString:@"enable-borders"]) {
            gOutlineConfig.enabled = true;
            printf("Window borders enabled\n");
        }
        else if ([arg isEqualToString:@"disable-borders"]) {
            gOutlineConfig.enabled = false;
            printf("Window borders disabled\n");
        }
        else if ([arg isEqualToString:@"set-border-width"]) {
            if (argc < 3) {
                printf("Error: set-border-width requires a value\n");
                return 1;
            }
            float width = atof(argv[2]);
            gOutlineConfig.width = width;
            printf("Border width set to %.1f\n", width);
        }
        else if ([arg isEqualToString:@"set-border-radius"]) {
            if (argc < 3) {
                printf("Error: set-border-radius requires a value\n");
                return 1;
            }
            float radius = atof(argv[2]);
            gOutlineConfig.cornerRadius = radius;
            printf("Border radius set to %.1f\n", radius);
        }
        else if ([arg isEqualToString:@"enable-resize"]) {
            gWindowSizeConstraintsConfig.enabled = false;
            printf("Free window resizing enabled\n");
        }
        else if ([arg isEqualToString:@"disable-resize"]) {
            gWindowSizeConstraintsConfig.enabled = true;
            printf("Free window resizing disabled\n");
        }
        else {
            printf("Unknown command: %s\n", argv[1]);
            return 1;
        }

        // Notify all windows to update
        updateAllWindows();
        
        // Give windows time to update
        usleep(100000);  // 100ms
    }
    return 0;
}
