// #import <AppKit/AppKit.h>
// #import "ZKSwizzle.h"

// @interface AlwaysOnTopController : NSObject
// @end

// @implementation AlwaysOnTopController

// + (void)load {
//     // Nothing needed here since we just want the swizzle
// }

// + (NSString *)yabaiPath {
//     NSTask *task = [[NSTask alloc] init];
//     [task setLaunchPath:@"/bin/which"];
//     [task setArguments:@[@"yabai"]];
    
//     NSPipe *pipe = [NSPipe pipe];
//     [task setStandardOutput:pipe];
    
//     NSFileHandle *file = [pipe fileHandleForReading];
    
//     @try {
//         [task launch];
        
//         NSData *data = [file readDataToEndOfFile];
//         NSString *path = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        
//         if (path) {
//             NSCharacterSet *whitespaceSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
//             return [path stringByTrimmingCharactersInSet:whitespaceSet];
//         }
//     } @catch (NSException *exception) {
//         NSLog(@"Error finding yabai: %@", exception);
//     } @finally {
//         [file closeFile];
//     }
    
//     return nil;
// }

// + (BOOL)isWindowManagedByYabai:(CGWindowID)windowID {
//     NSDictionary *windowInfo = [self getYabaiWindowInfo:windowID];
//     if (!windowInfo) {
//         return NO;
//     }
    
//     @try {
//         // Check for any of the states that should trigger always-on-top
        
//         // 1. Check if window is floating
//         if ([[windowInfo objectForKey:@"is-floating"] boolValue]) {
//             NSLog(@"Window is floating");
//             return YES;
//         }
        
//         // 2. Check if window has zoom-fullscreen
//         if ([[windowInfo objectForKey:@"has-fullscreen-zoom"] boolValue]) {
//             NSLog(@"Window has zoom-fullscreen");
//             return YES;
//         }
        
//         NSLog(@"Window is managed by yabai but not in floating or zoom-fullscreen state");
//         return NO;
        
//     } @catch (NSException *exception) {
//         NSLog(@"Error checking yabai state: %@", exception);
//         return NO;
//     }
// }

// + (NSDictionary *)getYabaiWindowInfo:(CGWindowID)windowID {
//     NSLog(@"Checking yabai state for window ID: %u", windowID);
    
//     NSTask *task = [[NSTask alloc] init];
//     [task setLaunchPath:[self yabaiPath]];
//     [task setArguments:@[@"-m", @"query", @"--windows"]];
    
//     NSPipe *pipe = [NSPipe pipe];
//     [task setStandardOutput:pipe];
    
//     NSFileHandle *file = [pipe fileHandleForReading];
    
//     @try {
//         [task launch];
        
//         NSData *data = [file readDataToEndOfFile];
//         NSError *error = nil;
        
//         NSArray *windows = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
//         if (error) {
//             NSLog(@"Error parsing yabai output: %@", error);
//             return nil;
//         }
        
//         for (NSDictionary *window in windows) {
//             if ([[window objectForKey:@"id"] unsignedIntValue] == windowID) {
//                 return window;
//             }
//         }
//     } @catch (NSException *exception) {
//         NSLog(@"Error querying yabai: %@", exception);
//     } @finally {
//         [file closeFile];
//     }
    
//     return nil;
// }

// @end
