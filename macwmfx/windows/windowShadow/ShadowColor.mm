// //
// //  ShadowColor.mm
// //  macwmfx
// //
// //  Created by Alex "aspauldingcode" on 11/13/24.
// //  Copyright (c) 2025 Alex "aspauldingcode". All rights reserved.
// //

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <CoreGraphics/CoreGraphics.h>
#import <CoreImage/CoreImage.h>
#include "../../headers/macwmfx_globals.h"
#include <objc/runtime.h>
#include <dlfcn.h>

// Global shadow config
extern ShadowConfig gShadowConfig;
CFDictionaryRef (*OriginalShadowDataFunc)(int windowID);
