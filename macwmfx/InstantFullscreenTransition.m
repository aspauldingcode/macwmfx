//
//  InstantFullscreenTransition.m
//  macwmfx
//
//  Created by Alex "aspauldingcode" on 11/13/24.
//  Copyright (c) 2024 Alex "aspauldingcode". All rights reserved.
//

#import "ZKSwizzle.h"
#import <Cocoa/Cocoa.h>

/*
 * To debug Dock space transitions with Frida:
 * 
 * 1. Install Frida: pip install frida-tools
 * 
 * 2. Trace C functions in Dock:
 *    frida-trace -n Dock -i "*space*"          # Trace all functions with "space" in name
 *   frida-trace -n Dock -i "*transition*"     # Trace transition-related functions
 *    frida-trace -n Dock -i "*animation*"      # Trace animation-related functions
 *    frida-trace -n Dock -i "*workspace*"      # Trace workspace-related functions
 * 
 * 3. For Objective-C methods, create dock_spaces.js:
 *    if (ObjC.available) {
 *        var dock = ObjC.classes.DOCKSpaces;
 *        Interceptor.attach(dock["- switchToSpace:"].implementation, {
 *            onEnter: function(args) {
 *                console.log("[*] switchToSpace: called");
 *                console.log("\tSpace:", new ObjC.Object(args[2]));
 *            }
 *        });
 *    }
 * 
 * 4. Run the Objective-C trace:
 *    frida -n Dock -l dock_spaces.js
 * 
 * This will help identify both C functions and Objective-C methods used during transitions.
 */

// Window fullscreen behavior
ZKSwizzleInterface(BS_NSWindow_InstantFullscreen, NSWindow, NSWindow)
@implementation BS_NSWindow_InstantFullscreen

- (void)toggleFullScreen:(id)sender {
    NSWindow *window = (NSWindow *)self;
    
    // Disable all possible animations
    [window setAnimationBehavior:NSWindowAnimationBehaviorNone];
    [[NSAnimationContext currentContext] setDuration:0.0];
    
    // Set window behavior for instant transitions
    [window setCollectionBehavior:(NSWindowCollectionBehaviorFullScreenPrimary | 
                                  NSWindowCollectionBehaviorStationary |
                                  NSWindowCollectionBehaviorMoveToActiveSpace)];
    
    // Disable window animations
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:0.0];
    
    ZKOrig(void, sender);
    
    [NSAnimationContext endGrouping];
}

- (void)setFrame:(NSRect)frameRect display:(BOOL)flag animate:(BOOL)animateFlag {
    // Force disable animation for frame changes
    ZKOrig(void, frameRect, flag, NO);
}

- (void)setAnimationBehavior:(NSWindowAnimationBehavior)newAnimationBehavior {
    // Force no animation behavior
    ZKOrig(void, NSWindowAnimationBehaviorNone);
}

@end
