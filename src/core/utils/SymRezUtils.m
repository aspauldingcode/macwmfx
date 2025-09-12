//
//  SymRezUtils.m
//  macwmfx
//
//  Created by Alex "aspauldingcode" on 01/09/25.
//  Copyright (c) 2025 Alex "aspauldingcode". All rights reserved.
//

#import "SymRezUtils.h"
#import <dlfcn.h>
#import "../../shared/macwmfx_logging.h"
#import "../../SymRez/SymRez.h"

// Static callback for sr_for_each
static bool symbolCallback(sr_symbol_t symbol, sr_ptr_t ptr, void *context) {
    NSMutableArray<NSString *> *symbolArray = (__bridge NSMutableArray<NSString *> *)context;
    [symbolArray addObject:@(symbol)];
    return false; // Continue iteration
}

@implementation SymRezUtils

+ (void *)resolveSymbol:(const char *)symbolName inFramework:(const char *)frameworkName {
    symrez_t symrez = symrez_new(frameworkName);
    if (!symrez) {
        MACWMFX_LOG_ERROR(macwmfx_log_general, "Failed to create SymRez for framework: %s", frameworkName);
        return NULL;
    }

    void *symbol = sr_resolve_symbol(symrez, symbolName);
    if (!symbol) {
        MACWMFX_LOG_ERROR(macwmfx_log_general, "Failed to resolve symbol %s in framework %s", symbolName, frameworkName);
    } else {
        MACWMFX_LOG_DEBUG(macwmfx_log_general, "Successfully resolved symbol %s in framework %s", symbolName, frameworkName);
    }

    sr_free(symrez);
    return symbol;
}

+ (void *)resolveSymbol:(const char *)symbolName inImage:(const char *)imageName {
    return symrez_resolve_once(imageName, symbolName);
}

+ (void *)resolveSymbolInAppKit:(const char *)symbolName {
    return [self resolveSymbol:symbolName inFramework:"AppKit"];
}

+ (void *)resolveSymbolInCoreGraphics:(const char *)symbolName {
    return [self resolveSymbol:symbolName inFramework:"CoreGraphics"];
}

+ (void *)resolveSymbolInQuartzCore:(const char *)symbolName {
    return [self resolveSymbol:symbolName inFramework:"QuartzCore"];
}

+ (void *)resolveGlobalVariable:(const char *)variableName inFramework:(const char *)frameworkName {
    // For global variables, we need to resolve the symbol and dereference it
    void *symbol = [self resolveSymbol:variableName inFramework:frameworkName];
    if (symbol) {
        return *(void **)symbol;
    }
    return NULL;
}

+ (BOOL)isSymbolAvailable:(const char *)symbolName inFramework:(const char *)frameworkName {
    void *symbol = [self resolveSymbol:symbolName inFramework:frameworkName];
    return symbol != NULL;
}

+ (NSArray<NSString *> *)listSymbolsInFramework:(const char *)frameworkName {
    NSMutableArray<NSString *> *symbols = [NSMutableArray array];

    symrez_t symrez = symrez_new(frameworkName);
    if (!symrez) {
        return symbols;
    }

    sr_for_each(symrez, (__bridge void *)symbols, symbolCallback);

    sr_free(symrez);
    return [symbols copy];
}

@end
