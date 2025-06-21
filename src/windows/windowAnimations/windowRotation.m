// #import "../../headers/macwmfx_globals.h"
// #import <Cocoa/Cocoa.h>
// #import <QuartzCore/QuartzCore.h>

// ZKSwizzleInterface(BS_NSWindow_Spin, NSWindow, NSWindow)

// @implementation BS_NSWindow_Spin

// - (void)makeKeyAndOrderFront:(id)sender {
//     ZKOrig(void, sender);
    
//     NSView *windowFrame = self.contentView.superview;
//     windowFrame.wantsLayer = YES;

//     CABasicAnimation *spinAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
//     spinAnimation.fromValue = @(0.0);
//     spinAnimation.toValue = @(2 * M_PI);
//     spinAnimation.duration = 2.0; 
//     spinAnimation.repeatCount = HUGE_VALF;

//     windowFrame.layer.anchorPoint = CGPointMake(0.5, 0.5);
//     [windowFrame.layer addAnimation:spinAnimation forKey:@"spinAnimation"];
// }

// @end
