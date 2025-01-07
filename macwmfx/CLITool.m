#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "macwmfx_globals.h"

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

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // Check if we have at least one argument
        if (argc < 2) {
            printf("Usage: macwmfx <command>\n");
            printf("Commands:\n");
            printf("  enable-borders     Enable window borders\n");
            printf("  disable-borders    Disable window borders\n");
            printf("  set-border-width   Set border width (requires additional value)\n");
            printf("  set-border-radius  Set border radius (requires additional value)\n");
            printf("  enable-resize      Enable free window resizing\n");
            printf("  disable-resize     Disable free window resizing\n");
            return 1;
        }

        NSString *command = [NSString stringWithUTF8String:argv[1]];
        
        // Modify global variables directly
        if ([command isEqualToString:@"enable-borders"]) {
            gOutlineEnabled = YES;
            printf("Window borders enabled\n");
        }
        else if ([command isEqualToString:@"disable-borders"]) {
            gOutlineEnabled = NO;
            printf("Window borders disabled\n");
        }
        else if ([command isEqualToString:@"set-border-width"]) {
            if (argc < 3) {
                printf("Error: set-border-width requires a value\n");
                return 1;
            }
            float width = atof(argv[2]);
            gOutlineWidth = width;
            printf("Border width set to %.1f\n", width);
        }
        else if ([command isEqualToString:@"set-border-radius"]) {
            if (argc < 3) {
                printf("Error: set-border-radius requires a value\n");
                return 1;
            }
            float radius = atof(argv[2]);
            gOutlineCornerRadius = radius;
            printf("Border radius set to %.1f\n", radius);
        }
        else if ([command isEqualToString:@"enable-resize"]) {
            gDisableWindowSizeConstraints = YES;
            printf("Free window resizing enabled\n");
        }
        else if ([command isEqualToString:@"disable-resize"]) {
            gDisableWindowSizeConstraints = NO;
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
