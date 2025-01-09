//
//  defineGlobals.m
//  macwmfx
//
//  Created by Alex "aspauldingcode" on 01/09/25.
//  Copyright (c) 2025 Alex "aspauldingcode". All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "../headers/macwmfx_globals.h"

// Global Configuration Variables
BOOL gIsEnabled = YES;
HotloadConfig gHotloadConfig = {NO, 1};  // Disabled by default, 1 second interval
BlurConfig gBlurConfig = {NO, 20, 20.0};
TitlebarConfig gTitlebarConfig = {0};
CustomTitleConfig gCustomTitleConfig = {0};
TrafficLightsConfig gTrafficLightsConfig = {
    .enabled = NO,
    .style = nil,
    .shape = nil,
    .order = nil,
    .position = nil,
    .size = 0,
    .customColor = {
        .enabled = NO,
        .active = {
            .stop = nil,
            .yield = nil,
            .go = nil
        },
        .inactive = {
            .stop = nil,
            .yield = nil,
            .go = nil
        },
        .hover = {
            .stop = nil,
            .yield = nil,
            .go = nil
        }
    }
};
ShadowConfig gShadowConfig = {0};
WindowSizeConstraintsConfig gWindowSizeConstraintsConfig = {0};
OutlineConfig gOutlineConfig = {0};
TransparencyConfig gTransparencyConfig = {0};
SystemColorConfig gSystemColorConfig = {0};

// CLI flag
BOOL gRunningFromCLI = NO;
