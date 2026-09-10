# macwmfx Development Guide
 
 This guide outlines the architecture and development principles for **macwmfx**, a declarative customization engine for Cocoa windows on macOS.

## Core Philosophy
 
 macwmfx shifts away from hardcoded window tweaks towards a **declarative, material-driven architecture**. Instead of manipulating individual windows with ad-hoc code, developers define a rich set of **Appearance Rules** in a JSON configuration. The engine then ensures that every window on the system (or matching specific criteria) adheres to these rules.

## Architecture Overview

### 1. Configuration Engine (`ConfigParser`)
- **JSON Schema**: All configurations must validate against the central schema.
- **Dynamic Rules**: Supports per-app overrides, focus-state transitions (active/inactive), and window-type logic.
- **Live Reload**: Changes to `config.json` are detected and applied instantly via the XPC command `macwmfx --reload`.

### 2. Orchestration (`macwmfx`)
- **Lifecycle Hooking**: Monitors window creation and destruction via `NSNotificationCenter`.
- **Global Orchestrator**: Manages the application of styles across multiple processes.

### 3. Styling Engine (`macwmfxStyler`)
 This is where the magic happens. It leverages low-level AppKit and CoreAnimation APIs to manipulate:
- **NSWindow**: Chrome style, transparency, and clipping.
- **NSThemeFrame**: The private view responsible for window decorations.
- **CALayers**: Injects custom layers for borders, gradients, and animated glows.
- **CGS (CoreGraphics Services)**: Fine-grained control over window shadows and backdrop filters.

## Adding New Effects

To add a new visual effect to Apple Sharpener:

### 1. Update the Schema
 Add the new property to the relevant section (`geometry`, `materials`, `decoration`, etc.) in the project's design documentation.
 
 ### 2. Implement the Styler logic
 Extend `macwmfxStyler` to handle the new property. Use the provided logging macros to track the application of the effect:
```objc
MACWMFX_LOG_DEBUG(macwmfx_log_server, "Applying cinematic blur: %f", radius);
```

### 3. Expose to Config
Update `ConfigParser.m` to read the new property from the JSON and pass it to the styler.

## Development Rules

- **Respect ARC**: Do not use `xpc_release` or manual memory management for Objective-C objects.
- **Thread Safety**: Window styling must always happen on the **Main Queue**.
- **Performance**: Heavy blur or complex shadow stacks can impact WindowServer performance. Always profile your effects.
- **Modern Logging**: Use the `MACWMFX_LOG_*` macros defined in `macwmfx_logging.h`.

## Key Directories

- `src/core/`: Foundation logic (configuration, logging).
- `src/main/`: Orchestrator and Hooking.
- `src/modules/`: Individual effect implementation (legacy logic being migrated).
- `src/server/`: XPC background service.
- `src/client/`: CLI tool and client library.
