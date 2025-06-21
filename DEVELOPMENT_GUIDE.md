# macwmfx Development Guide

## 🎯 Feature Flag System for Development

This guide explains how to selectively enable/disable code during development to
handle conflicts, problematic features, or experimental code without losing any
work.

## 🚀 Quick Start

### Basic Usage

```bash
# Debug build with all features
make debug

# Minimal build with only core features
make minimal

# Disable specific features
make debug ENABLE_WINDOW_SHADOWS=0

# Build for experimentation
make experimental
```

## 📋 Build Configurations

### Pre-defined Configurations

| Configuration  | Description                         | Use Case                             |
| -------------- | ----------------------------------- | ------------------------------------ |
| `debug`        | All features enabled, debug symbols | Development, testing                 |
| `release`      | All features enabled, optimized     | Production builds                    |
| `minimal`      | Only core features enabled          | Troubleshooting, basic functionality |
| `experimental` | All features + experimental ones    | Testing new features                 |

### Configuration Examples

```bash
# Standard development
make debug

# Production release
make release

# Minimal for troubleshooting
make minimal

# Experimental features
make experimental
```

## 🎛️ Feature Flags

### Available Feature Flags

| Flag                         | Default | Description                  |
| ---------------------------- | ------- | ---------------------------- |
| `ENABLE_WINDOW_BORDERS`      | 1       | Window border rendering      |
| `ENABLE_WINDOW_SHADOWS`      | 1       | Window shadow effects        |
| `ENABLE_WINDOW_TRANSPARENCY` | 1       | Window transparency/opacity  |
| `ENABLE_WINDOW_BLUR`         | 1       | Window blur effects          |
| `ENABLE_TITLEBAR_TWEAKS`     | 1       | Titlebar modifications       |
| `ENABLE_TRAFFIC_LIGHTS`      | 1       | Traffic light button tweaks  |
| `ENABLE_RESIZE_LIMITS`       | 1       | Window resize constraints    |
| `ENABLE_DOCK_TWEAKS`         | 1       | Dock modifications           |
| `ENABLE_MENUBAR_TWEAKS`      | 1       | Menubar modifications        |
| `ENABLE_SPACES_TWEAKS`       | 1       | Spaces/desktop tweaks        |
| `ENABLE_ADVANCED_SHADOWS`    | 0       | Experimental shadow features |
| `ENABLE_CUSTOM_ANIMATIONS`   | 0       | Custom animation system      |

### Feature Flag Usage

```bash
# Disable problematic window blur
make debug ENABLE_WINDOW_BLUR=0

# Test without dock tweaks
make debug ENABLE_DOCK_TWEAKS=0

# Build with only shadows and transparency
make debug ENABLE_WINDOW_BORDERS=0 ENABLE_TITLEBAR_TWEAKS=0 ENABLE_TRAFFIC_LIGHTS=0

# Enable experimental features
make debug ENABLE_ADVANCED_SHADOWS=1 ENABLE_CUSTOM_ANIMATIONS=1
```

## 💻 Code Implementation

### Using Feature Flags in Code

```objc
// In your .m/.mm files
#import "../headers/macwmfx_globals.h"

- (void)setupWindow:(NSWindow *)window {
#if MACWMFX_ENABLE_WINDOW_BORDERS
    // This code only compiles if borders are enabled
    [self setupWindowBorders:window];
#endif

#if MACWMFX_ENABLE_WINDOW_SHADOWS
    // Shadow code - can be disabled if problematic
    [self setupWindowShadows:window];
#endif

#if MACWMFX_ENABLE_ADVANCED_SHADOWS
    // Experimental features - disabled by default
    [self setupAdvancedShadows:window];
#endif
}

#if MACWMFX_ENABLE_WINDOW_BORDERS
// Entire functions can be conditionally compiled
- (void)setupWindowBorders:(NSWindow *)window {
    // Implementation here
}
#endif
```

### Debug Logging

```objc
// Debug logging - only active in debug builds
DLog(@"Setting up window features");

// Verbose logging - extra detailed output
VLog(@"Processing window: %@", window);
```

## 🔧 Development Workflows

### 1. Feature Development Workflow

```bash
# Start with minimal build to ensure core works
make minimal

# Add your feature with flag disabled initially
# Edit code with: #if MACWMFX_ENABLE_YOUR_FEATURE

# Test with feature enabled
make debug ENABLE_YOUR_FEATURE=1

# Test with feature disabled
make debug ENABLE_YOUR_FEATURE=0
```

### 2. Debugging Problematic Code

```bash
# If a feature is causing crashes, disable it
make debug ENABLE_PROBLEMATIC_FEATURE=0

# Test different combinations to isolate issues
make debug ENABLE_WINDOW_BLUR=0 ENABLE_TITLEBAR_TWEAKS=0

# Use minimal build to test core functionality
make minimal
```

### 3. Experimental Feature Testing

```bash
# Enable experimental features
make experimental

# Or selectively enable specific experimental features
make debug ENABLE_ADVANCED_SHADOWS=1
```

## 📁 File Organization

### Adding New Features

1. **Create feature files** in appropriate directories:

   ```
   src/windows/yourFeature/YourFeature.m
   ```

2. **Add feature flag** to `src/headers/macwmfx_globals.h`:

   ```c
   #define MACWMFX_ENABLE_YOUR_FEATURE 1
   ```

3. **Add to Makefile** feature flags section:

   ```makefile
   ENABLE_YOUR_FEATURE ?= 1
   ```

4. **Add compiler flag**:

   ```makefile
   -DMACWMFX_ENABLE_YOUR_FEATURE=$(ENABLE_YOUR_FEATURE)
   ```

5. **Use in code**:
   ```objc
   #if MACWMFX_ENABLE_YOUR_FEATURE
   // Your feature code here
   #endif
   ```

## 🚨 Best Practices

### DO ✅

- **Use feature flags** for new/experimental code
- **Test both enabled and disabled states** of features
- **Use descriptive flag names** (ENABLE_WINDOW_BORDERS vs ENABLE_BORDERS)
- **Document what each flag does** in this guide
- **Default experimental features to 0** (disabled)
- **Use DLog/VLog** for debugging instead of NSLog in production

### DON'T ❌

- **Don't comment out large blocks of code** - use feature flags instead
- **Don't delete working code** during development - disable it with flags
- **Don't leave experimental features enabled by default**
- **Don't use feature flags for small, stable features** - they add complexity

### Code Organization

```objc
// Good: Feature-specific conditional compilation
#if MACWMFX_ENABLE_WINDOW_BLUR
- (void)setupBlur:(NSWindow *)window {
    // Blur implementation
}
#endif

// Good: Conditional method calls
- (void)setupWindow:(NSWindow *)window {
#if MACWMFX_ENABLE_WINDOW_BLUR
    [self setupBlur:window];
#endif
}

// Avoid: Large commented blocks
/*
- (void)setupBlur:(NSWindow *)window {
    // This approach makes it hard to track what's disabled
}
*/
```

## 🧪 Testing Different Configurations

### Comprehensive Testing Script

```bash
#!/bin/bash
# Test all configurations
echo "Testing all build configurations..."

make clean
make debug && echo "✓ Debug build successful"
make clean
make release && echo "✓ Release build successful"
make clean
make minimal && echo "✓ Minimal build successful"
make clean
make experimental && echo "✓ Experimental build successful"

# Test feature combinations
make clean
make debug ENABLE_WINDOW_BLUR=0 && echo "✓ No blur build successful"
```

## 🎯 Common Development Scenarios

### Scenario 1: Feature Causing Crashes

```bash
# Disable the problematic feature
make debug ENABLE_PROBLEMATIC_FEATURE=0

# Test if crash is resolved
# If yes, debug the feature code
# If no, try disabling other features
```

### Scenario 2: Testing Feature Interactions

```bash
# Test features in isolation
make debug ENABLE_WINDOW_BORDERS=1 ENABLE_WINDOW_SHADOWS=0 ENABLE_WINDOW_BLUR=0

# Test combinations
make debug ENABLE_WINDOW_BORDERS=1 ENABLE_WINDOW_SHADOWS=1 ENABLE_WINDOW_BLUR=0
```

### Scenario 3: Preparing for Release

```bash
# Test minimal configuration
make minimal

# Test full release
make release

# Test without experimental features
make release ENABLE_ADVANCED_SHADOWS=0 ENABLE_CUSTOM_ANIMATIONS=0
```

## 🔍 Debugging Tips

### Build Issues

```bash
# Clean build if you get weird errors
make clean
make debug

# Check which features are enabled
make help

# Verbose compilation to see all flags
make debug V=1
```

### Runtime Issues

```objc
// Use debug logging to trace execution
DLog(@"Feature X is %s", MACWMFX_ENABLE_FEATURE_X ? "enabled" : "disabled");

// Check feature status at runtime
#if MACWMFX_DEBUG
    NSLog(@"Debug build - all logging enabled");
#endif
```

## 📊 Summary

The feature flag system provides:

- ✅ **Selective compilation** - only build what you need
- ✅ **Easy debugging** - disable problematic features quickly
- ✅ **Safe experimentation** - test new features without breaking working code
- ✅ **Multiple configurations** - debug, release, minimal, experimental
- ✅ **No code loss** - never delete working code, just disable it
- ✅ **Build optimization** - smaller binaries with fewer features

This system replaces the need to comment out code, manually exclude files, or
delete working implementations during development.
