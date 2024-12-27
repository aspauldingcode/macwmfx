#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import "ZKSwizzle.h"

@interface NSWindow (Private)
- (void)setOpaque:(BOOL)opaque;
- (void)setBackgroundColor:(NSColor *)color;
- (CALayer *)contentView;
@end

@interface CornerRadiusController : NSObject
@end

@implementation CornerRadiusController

+ (void)load {
    Method maskMethod = class_getInstanceMethod(NSClassFromString(@"NSWindow"), @selector(_cornerMask));
    IMP maskIMP = imp_implementationWithBlock(^id(NSWindow *self) {
        // Make window transparent and non-opaque
        [self setOpaque:NO];
        [self setBackgroundColor:[NSColor clearColor]];
        
        // Get window size
        NSRect frame = [self frame];
        CGFloat size = MIN(frame.size.width, frame.size.height);
        
        // Create star shape
        NSBezierPath *starPath = [NSBezierPath bezierPath];
        CGFloat centerX = size / 2;
        CGFloat centerY = size / 2;
        CGFloat outerRadius = size / 2;
        CGFloat innerRadius = outerRadius * 0.382; // Golden ratio
        
        for (int i = 0; i < 10; i++) {
            CGFloat radius = (i % 2 == 0) ? outerRadius : innerRadius;
            CGFloat angle = i * M_PI / 5 - M_PI / 2; // Start from top point
            
            CGFloat x = centerX + radius * cos(angle);
            CGFloat y = centerY + radius * sin(angle);
            
            if (i == 0) {
                [starPath moveToPoint:NSMakePoint(x, y)];
            } else {
                [starPath lineToPoint:NSMakePoint(x, y)];
            }
        }
        [starPath closePath];
        
        // Create mask image
        NSImage *maskImage = [[NSImage alloc] initWithSize:NSMakeSize(size, size)];
        [maskImage lockFocus];
        [[NSColor whiteColor] set];
        [starPath fill];
        [maskImage unlockFocus];
        
        // Apply mask to window's content view layer
        CALayer *contentLayer = [self contentView].layer;
        if (contentLayer) {
            contentLayer.mask = [CAShapeLayer layer];
            ((CAShapeLayer *)contentLayer.mask).path = starPath.CGPath;
        }
        
        return maskImage;
    });
    method_setImplementation(maskMethod, maskIMP);
}

@end