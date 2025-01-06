#import <Foundation/Foundation.h>
#import "macwmfx_globals.h"

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
            return 1;
        }

        // Get shared memory
        SharedMemory* shared = getSharedMemory();
        if (!shared) {
            printf("Error: Failed to access shared memory\n");
            return 1;
        }

        NSString *command = [NSString stringWithUTF8String:argv[1]];
        
        if ([command isEqualToString:@"enable-borders"]) {
            shared->outlineEnabled = YES;
            printf("Window borders enabled\n");
        }
        else if ([command isEqualToString:@"disable-borders"]) {
            shared->outlineEnabled = NO;
            printf("Window borders disabled\n");
        }
        else if ([command isEqualToString:@"set-border-width"]) {
            if (argc < 3) {
                printf("Error: set-border-width requires a value\n");
                return 1;
            }
            float width = atof(argv[2]);
            shared->outlineWidth = width;
            printf("Border width set to %.1f\n", width);
        }
        else if ([command isEqualToString:@"set-border-radius"]) {
            if (argc < 3) {
                printf("Error: set-border-radius requires a value\n");
                return 1;
            }
            float radius = atof(argv[2]);
            shared->outlineCornerRadius = radius;
            printf("Border radius set to %.1f\n", radius);
        }
        else {
            printf("Unknown command: %s\n", argv[1]);
            return 1;
        }

        // Signal that an update is needed
        shared->updateNeeded = YES;

        // Post notification to trigger update
        [[NSDistributedNotificationCenter defaultCenter] 
            postNotificationName:@"com.macwmfx.settingsChanged"
                        object:nil
                      userInfo:nil
            deliverImmediately:YES];

        // Give the dylib some time to process the update
        usleep(100000);  // 100ms
    }
    return 0;
}
