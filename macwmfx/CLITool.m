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

        NSString *command = [NSString stringWithUTF8String:argv[1]];
        
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
        else {
            printf("Unknown command: %s\n", argv[1]);
            return 1;
        }

        // Restart the ammonia injector to apply changes
        printf("Restarting ammonia...\n");
        system("sudo pkill -9 ammonia");
        system("sudo launchctl bootout system /Library/LaunchDaemons/com.bedtime.ammonia.plist");
        system("sudo launchctl bootstrap system /Library/LaunchDaemons/com.bedtime.ammonia.plist");
        printf("Changes applied and ammonia restarted\n");
    }
    return 0;
}
