//
//  SymRezUtils.h
//  macwmfx
//
//  Created by Alex "aspauldingcode" on 01/09/25.
//  Copyright (c) 2025 Alex "aspauldingcode". All rights reserved.
//

#import <Foundation/Foundation.h>
#import "../../SymRez/SymRez.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * SymRezUtils - Utility functions for SymRez integration
 *
 * Provides convenient wrappers around SymRez functionality for
 * resolving private symbols and accessing internal macOS APIs.
 */
@interface SymRezUtils : NSObject

// Framework symbol resolution
+ (void * _Nullable)resolveSymbol:(const char *)symbolName inFramework:(const char *)frameworkName;
+ (void * _Nullable)resolveSymbol:(const char *)symbolName inImage:(const char *)imageName;

// System framework shortcuts
+ (void * _Nullable)resolveSymbolInAppKit:(const char *)symbolName;
+ (void * _Nullable)resolveSymbolInCoreGraphics:(const char *)symbolName;
+ (void * _Nullable)resolveSymbolInQuartzCore:(const char *)symbolName;

// Global variable access
+ (void * _Nullable)resolveGlobalVariable:(const char *)variableName inFramework:(const char *)frameworkName;

// Utility methods
+ (BOOL)isSymbolAvailable:(const char *)symbolName inFramework:(const char *)frameworkName;
+ (NSArray<NSString *> *)listSymbolsInFramework:(const char *)frameworkName;

@end

// Convenience macros
#define SYMREZ_RESOLVE(framework, symbol) [SymRezUtils resolveSymbol:symbol inFramework:framework]
#define SYMREZ_APPKIT(symbol) [SymRezUtils resolveSymbolInAppKit:symbol]
#define SYMREZ_COREGRAPHICS(symbol) [SymRezUtils resolveSymbolInCoreGraphics:symbol]
#define SYMREZ_QUARTZCORE(symbol) [SymRezUtils resolveSymbolInQuartzCore:symbol]

NS_ASSUME_NONNULL_END
