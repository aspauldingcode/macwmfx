// //
// //  NoMenubar.m
// //  macwmfx
// //
// //  Created by Alex "aspauldingcode" on 11/13/24.
// //  Copyright (c) 2024 Alex "aspauldingcode". All rights reserved.
// //

// #import "../headers/macwmfx_globals.h"

// ZKSwizzleInterface(BS_NSMenu_NoMenubar, NSMenu, NSMenu)

// @implementation BS_NSMenu_NoMenubar

// - (void)setMenuBarVisible:(BOOL)visible {
//     // Always set menubar to invisible
//     ZKOrig(void, NO);
// }

// - (BOOL)menuBarVisible {
//     // Always return NO to indicate menubar is not visible
//     return NO;
// }

// @end

// ZKSwizzleInterface(BS_NSApplication_NoMenubar, NSApplication, NSApplication)

// @implementation BS_NSApplication_NoMenubar

// - (void)setPresentationOptions:(NSApplicationPresentationOptions)options {
//     // Add the auto-hide menu bar option to whatever options are being set
//     options |= NSApplicationPresentationAutoHideMenuBar;
//     ZKOrig(void, options);
// }

// - (NSApplicationPresentationOptions)presentationOptions {
//     // Add auto-hide menu bar to the current presentation options
//     NSApplicationPresentationOptions options = ZKOrig(NSApplicationPresentationOptions);
//     return options | NSApplicationPresentationAutoHideMenuBar;
// }

// @end
