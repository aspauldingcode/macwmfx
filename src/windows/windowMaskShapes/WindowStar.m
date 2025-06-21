//
//  WindowStar.m
//  macwmfx
//
//  Created by Alex "aspauldingcode" on 11/13/24.
//  Copyright (c) 2024 Alex "aspauldingcode". All rights reserved.
//

#import "../../headers/macwmfx_globals.h"
#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>

// @interface NSWindow (Private)
// - (id)_cornerMask;
// @end

// @interface WindowStarController : NSObject
// @end

// @implementation WindowStarController

// + (void)load {
//     Method maskMethod = class_getInstanceMethod(NSClassFromString(@"NSWindow"), @selector(_cornerMask));
//     if (!maskMethod) return;
    
//     IMP maskIMP = imp_implementationWithBlock(^id(NSWindow *self) {
//         // Get window size
//         NSRect frame = [self frame];
//         CGFloat size = MIN(frame.size.width, frame.size.height);
        
//         // Create star shape
//         NSBezierPath *starPath = [NSBezierPath bezierPath];
//         CGFloat centerX = frame.size.width / 2;
//         CGFloat centerY = frame.size.height / 2;
//         CGFloat outerRadius = size / 2;
//         CGFloat innerRadius = outerRadius * 0.382; // Golden ratio
        
//         for (int i = 0; i < 10; i++) {
//             CGFloat radius = (i % 2 == 0) ? outerRadius : innerRadius;
//             CGFloat angle = i * M_PI / 5 - M_PI / 2; // Start from top point
            
//             CGFloat x = centerX + radius * cos(angle);
//             CGFloat y = centerY + radius * sin(angle);
            
//             if (i == 0) {
//                 [starPath moveToPoint:NSMakePoint(x, y)];
//             } else {
//                 [starPath lineToPoint:NSMakePoint(x, y)];
//             }
//         }
//         [starPath closePath];
        
//         // Create mask image
//         NSImage *maskImage = [[NSImage alloc] initWithSize:frame.size];
//         [maskImage lockFocus];
//         [[NSColor whiteColor] set];
//         [starPath fill];
//         [maskImage unlockFocus];
        
//         return maskImage;
//     });
    
//     method_setImplementation(maskMethod, maskIMP);
// }

// @end