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
BlurConfig gBlurConfig = {0};
TitlebarConfig gTitlebarConfig = {0};
CustomTitleConfig gCustomTitleConfig = {0};
TrafficLightsConfig gTrafficLightsConfig = {0};
ShadowConfig gShadowConfig = {0};
WindowSizeConstraintsConfig gWindowSizeConstraintsConfig = {0};
OutlineConfig gOutlineConfig = {0};
TransparencyConfig gTransparencyConfig = {0};
SystemColorConfig gSystemColorConfig = {0};

// CLI flag
BOOL gRunningFromCLI = NO;
