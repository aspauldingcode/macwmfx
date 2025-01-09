//
//  defineGlobals.m
//  macwmfx
//
//  Created by Alex "aspauldingcode" on 01/09/25.
//  Copyright (c) 2025 Alex "aspauldingcode". All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "../headers/macwmfx_globals.h"

// Define the globals with default values
BOOL gIsEnabled = YES;

BlurConfig gBlurConfig = {
    .enabled = YES,
    .passes = 1,
    .radius = 10.0
};

TitlebarConfig gTitlebarConfig = {
    .enabled = NO,
    .backgroundColor = nil,
    .foregroundColor = nil,
    .style = @"modern",
    .size = 22.0
};

TrafficLightsConfig gTrafficLightsConfig = {
    .enabled = NO,
    .stopColor = nil,
    .yieldColor = nil,
    .goColor = nil,
    .style = @"macOS",
    .size = 12.0,
    .position = @"top-left"
};

ShadowConfig gShadowConfig = {
    .enabled = NO,
    .color = nil
};

WindowSizeConstraintsConfig gWindowSizeConstraintsConfig = {
    .enabled = NO
};

OutlineConfig gOutlineConfig = {
    .enabled = YES,
    .activeColor = nil,
    .inactiveColor = nil,
    .stackedColor = nil,
    .cornerRadius = 40.0,
    .type = @"inline",
    .width = 2.0
};

TransparencyConfig gTransparencyConfig = {
    .enabled = YES,
    .value = 0.5
};

SystemColorConfig gSystemColorConfig = {
    .variant = @"dark",
    .slug = @"gruvbox-dark-soft",
    .colors = {0}  // Initialize all colors to nil
};

// Flag to indicate if we're running from CLI
BOOL gRunningFromCLI = NO;
