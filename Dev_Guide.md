# macwmfx Development Guide

## Overview

This guide covers development practices for macwmfx using the new modular, import-based architecture. The system uses runtime module loading instead of compile-time feature flags, providing better separation of concerns, runtime flexibility, and cleaner code organization.

## 🏗️ Modular Architecture

### Core Principles

- **Import-Based Loading**: Features are loaded only when explicitly imported or configured
- **Runtime Flexibility**: Enable/disable features without recompilation
- **Clean Separation**: Each feature is self-contained in its own module
- **Dependency Management**: Automatic dependency resolution between modules
- **Performance**: Only load features that are actually used

### Directory Structure

```text
src/
├── main/           # Core orchestrator (macwmfx)
│   ├── macwmfx.m          # Main orchestrator
│   ├── macwmfx.h          # Main header
│   └── module_loader.h    # Dynamic module loading
├── modules/        # Feature modules
│   ├── windows/
│   │   ├── WindowManager.m
│   │   ├── WindowManager.h
│   │   └── features/
│   │       ├── borders/
│   │       │   ├── WindowBorderModule.h
│   │       │   └── WindowBorderModule.m
│   │       ├── shadows/
│   │       ├── transparency/
│   │       ├── blur/
│   │       ├── titlebar/
│   │       └── trafficLights/
│   ├── dock/
│   │   ├── DockManager.m
│   │   └── DockManager.h
│   ├── menubar/
│   │   ├── MenubarManager.m
│   │   └── MenubarManager.h
│   └── spaces/
│       ├── SpacesManager.m
│       └── SpacesManager.h
├── core/           # Shared utilities
│   ├── config/
│   │   ├── ConfigManager.m
│   │   └── ConfigManager.h
│   ├── utils/
│   │   ├── ColorUtils.m
│   │   └── WindowUtils.m
│   └── types/
│       └── macwmfx_types.h
└── shared/         # Common libraries
    ├── headers/
    └── ZKSwizzle/
```

## 🎯 Module System

### Module Protocol

Every feature module implements the `macwmfx_module` protocol:

```objc
@protocol macwmfx_module <NSObject>
@required
+ (NSString *)moduleName;
+ (NSString *)moduleVersion;
+ (BOOL)loadModule;
+ (void)unloadModule;
+ (BOOL)isLoaded;
@optional
+ (NSArray<NSString *> *)dependencies;
+ (NSDictionary *)defaultConfiguration;
@end
```

### Module Registration

Modules are automatically registered using the convenience macro:

```objc
@implementation WindowBorderModule

+ (NSString *)moduleName {
    return @"window.borders";
}

+ (NSString *)moduleVersion {
    return @"1.0.0";
}

+ (BOOL)loadModule {
    // Initialize border system
    return YES;
}

+ (void)unloadModule {
    // Cleanup border system
}

+ (BOOL)isLoaded {
    return YES; // Track loading state
}

@end

MACWMFX_MODULE_REGISTER(WindowBorderModule)
```

### Dependency Management

Modules can declare dependencies on other modules:

```objc
+ (NSArray<NSString *> *)dependencies {
    return @[@"window.core", @"config.manager"];
}
```

## 🚀 Quick Start

### Building

```bash
# Debug build
make debug

# Release build
make release

# Clean build
make clean
```

### Configuration-Driven Loading

Modules are loaded based on JSON configuration:

```json
{
  "window": {
    "outline": {
      "enabled": true,
      "width": 2,
      "cornerRadius": 8
    },
    "blur": {
      "enabled": false
    }
  },
  "dock": {
    "enabled": true,
    "autohide": true
  }
}
```

Only modules with `"enabled": true` are loaded at runtime.

## 💻 Development Workflow

### 1. Creating a New Module

1. **Create module directory structure**:

   ```text
   src/modules/windows/features/yourFeature/
   ├── YourFeatureModule.h
   └── YourFeatureModule.m
   ```

2. **Implement the module protocol**:

   ```objc
   @interface YourFeatureModule : NSObject <macwmfx_module>
   // Your interface
   @end

   @implementation YourFeatureModule
   // Implementation with MACWMFX_MODULE_REGISTER
   @end
   ```

3. **Add to configuration schema**:

   ```json
   {
     "window": {
       "yourFeature": {
         "enabled": false,
         "setting1": "value1"
       }
     }
   }
   ```

4. **Register with manager**:

   ```objc
   // In WindowManager.m
   - (void)loadYourFeature {
       if ([self.moduleLoader isModuleLoaded:@"window.yourFeature"]) {
           YourFeatureModule *module = [YourFeatureModule sharedInstance];
           [module setupFeature];
       }
   }
   ```

### 2. Module Development Pattern

```objc
// YourFeatureModule.h
@interface YourFeatureModule : NSObject <macwmfx_module>

// Module protocol methods
+ (NSString *)moduleName;
+ (NSString *)moduleVersion;
+ (BOOL)loadModule;
+ (void)unloadModule;
+ (BOOL)isLoaded;

// Feature-specific methods
- (void)setupFeature;
- (void)teardownFeature;
- (void)updateConfiguration:(NSDictionary *)config;

@end

// YourFeatureModule.m
@implementation YourFeatureModule

+ (NSString *)moduleName {
    return @"window.yourFeature";
}

+ (BOOL)loadModule {
    // Initialize your feature
    // Set up hooks, observers, etc.
    return YES;
}

+ (void)unloadModule {
    // Clean up your feature
    // Remove hooks, observers, etc.
}

- (void)setupFeature {
    // Feature-specific setup
}

@end

MACWMFX_MODULE_REGISTER(YourFeatureModule)
```

### 3. Testing Modules

```objc
// Test individual module
- (void)testYourFeatureModule {
    YourFeatureModule *module = [[YourFeatureModule alloc] init];
    XCTAssertTrue([YourFeatureModule loadModule]);
    XCTAssertTrue([YourFeatureModule isLoaded]);
    [YourFeatureModule unloadModule];
}

// Test module integration
- (void)testModuleIntegration {
    WindowManager *manager = [[WindowManager alloc] init];
    [manager loadModulesFromConfiguration:testConfig];
    XCTAssertTrue([manager isModuleLoaded:@"window.yourFeature"]);
}
```

## 🔧 Configuration Management

### Configuration Structure

```json
{
  "hotload": {
    "enabled": true,
    "interval": 1
  },
  "window": {
    "outline": {
      "enabled": true,
      "width": 2,
      "cornerRadius": 8,
      "colors": {
        "active": "#fbf1c7",
        "inactive": "#d5c4a1"
      }
    },
    "blur": {
      "enabled": false,
      "radius": 10,
      "passes": 1
    }
  },
  "dock": {
    "enabled": true,
    "autohide": true,
    "position": "bottom"
  }
}
```

### Hot-Reload Support

Configuration changes are automatically detected and applied:

```objc
// In ConfigManager.m
- (void)startHotReload {
    // Monitor config file for changes
    // Automatically reload modules when config changes
}
```

## 📁 File Organization Guidelines

### Module Structure

```text
src/modules/category/features/featureName/
├── FeatureNameModule.h      # Module interface
├── FeatureNameModule.m      # Module implementation
├── FeatureNameManager.h     # Feature-specific manager (if needed)
├── FeatureNameManager.m     # Manager implementation
└── README.md               # Module documentation
```

### Naming Conventions

- **Modules**: `FeatureNameModule` (e.g., `WindowBorderModule`)
- **Managers**: `CategoryManager` (e.g., `WindowManager`)
- **Module names**: `category.feature` (e.g., `window.borders`)
- **Files**: `FeatureNameModule.h/m`

### Import Organization

```objc
// Standard import order
#import "FeatureNameModule.h"
#import "../core/config/ConfigManager.h"
#import "../shared/headers/CommonTypes.h"
#import <Cocoa/Cocoa.h>
```

## 🧪 Testing Strategy

### Unit Testing

```objc
// Test individual modules
- (void)testModuleLifecycle {
    XCTAssertTrue([TestModule loadModule]);
    XCTAssertTrue([TestModule isLoaded]);
    [TestModule unloadModule];
    XCTAssertFalse([TestModule isLoaded]);
}

// Test configuration loading
- (void)testConfigurationLoading {
    NSDictionary *config = @{@"feature": @{@"enabled": @YES}};
    [moduleLoader loadModulesFromConfiguration:config];
    XCTAssertTrue([moduleLoader isModuleLoaded:@"feature"]);
}
```

### Integration Testing

```objc
// Test module interactions
- (void)testModuleDependencies {
    [moduleLoader loadModuleWithDependencies:@"window.borders"];
    XCTAssertTrue([moduleLoader isModuleLoaded:@"window.core"]);
    XCTAssertTrue([moduleLoader isModuleLoaded:@"window.borders"]);
}
```

## 🚀 Performance Considerations

### Lazy Loading

Modules are loaded only when needed:

```objc
- (void)applyFeatureToWindow:(NSWindow *)window {
    if (![self.moduleLoader isModuleLoaded:@"window.feature"]) {
        return; // Skip if module not loaded
    }

    FeatureModule *module = [FeatureModule sharedInstance];
    [module applyToWindow:window];
}
```

### Memory Management

```objc
+ (void)unloadModule {
    // Clean up resources
    [self removeObservers];
    [self cleanupHooks];
    [self releaseResources];
}
```

## 🤝 Contributing

### Development Guidelines

1. **Follow modular architecture** - Create self-contained modules
2. **Use dependency injection** - Pass dependencies through constructors
3. **Implement proper lifecycle** - Handle load/unload correctly
4. **Test thoroughly** - Unit test each module
5. **Document clearly** - Include README for each module

### Code Review Checklist

- [ ] Module implements `macwmfx_module` protocol
- [ ] Proper error handling and logging
- [ ] Clean separation of concerns
- [ ] Configuration-driven behavior
- [ ] Proper resource cleanup
- [ ] Unit tests included
- [ ] Documentation updated

### Getting Started

1. **Familiarize yourself** with the module system
2. **Study existing modules** for patterns
3. **Create small modules first** to understand the system
4. **Test thoroughly** before submitting PRs
5. **Ask questions** if unsure about architecture

## 📚 Additional Resources

- **Configuration**: See `src/config/config_example.json` for configuration format
- **Module Examples**: See `src/modules/windows/features/borders/` for module implementation
- **Core System**: See `src/main/` for orchestrator and module loader
- **Build System**: See `Makefile` for build options

## 🔄 Migration Status

### Completed ✅

- [x] Core orchestrator (`macwmfx`)
- [x] Module loader system
- [x] Configuration manager
- [x] Basic module structure

### In Progress 🔄

- [ ] Window feature modules
- [ ] Dock and menubar modules
- [ ] Spaces modules
- [ ] Build system updates

### Planned 📋

- [ ] Remove old feature flag system
- [ ] Update documentation
- [ ] Performance optimization
- [ ] Comprehensive testing suite

This modular architecture provides a clean, maintainable foundation for macwmfx while enabling runtime flexibility and better code organization.
