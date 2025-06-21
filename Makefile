# macwmfx Build System with Feature Flags
# =======================================

# Dynamic compiler detection
XCODE_PATH := $(shell xcode-select -p)
CC := $(shell xcrun -find clang)
CXX := $(shell xcrun -find clang++)

# SDK paths
SDKROOT ?= $(shell xcrun --show-sdk-path)

# =============================================================================
# BUILD CONFIGURATION FLAGS
# =============================================================================

# Build configuration (debug, release, minimal, experimental)
CONFIG ?= debug

# Feature flags - can be overridden from command line
ENABLE_WINDOW_BORDERS ?= 1
ENABLE_WINDOW_SHADOWS ?= 1
ENABLE_WINDOW_TRANSPARENCY ?= 1
ENABLE_WINDOW_BLUR ?= 1
ENABLE_TITLEBAR_TWEAKS ?= 1
ENABLE_TRAFFIC_LIGHTS ?= 1
ENABLE_RESIZE_LIMITS ?= 1
ENABLE_DOCK_TWEAKS ?= 1
ENABLE_MENUBAR_TWEAKS ?= 1
ENABLE_SPACES_TWEAKS ?= 1
ENABLE_ADVANCED_SHADOWS ?= 0
ENABLE_CUSTOM_ANIMATIONS ?= 0

# Configuration-specific flags
ifeq ($(CONFIG),debug)
    CFLAGS_CONFIG = -DDEBUG=1 -g -O0
else ifeq ($(CONFIG),release)
    CFLAGS_CONFIG = -DNDEBUG=1 -O2
else ifeq ($(CONFIG),minimal)
    CFLAGS_CONFIG = -DNDEBUG=1 -O2
    # Disable most features for minimal build
    ENABLE_WINDOW_BORDERS = 0
    ENABLE_WINDOW_BLUR = 0
    ENABLE_TITLEBAR_TWEAKS = 0
    ENABLE_DOCK_TWEAKS = 0
    ENABLE_MENUBAR_TWEAKS = 0
    ENABLE_SPACES_TWEAKS = 0
else ifeq ($(CONFIG),experimental)
    CFLAGS_CONFIG = -DDEBUG=1 -g -O0
    # Enable experimental features
    ENABLE_ADVANCED_SHADOWS = 1
    ENABLE_CUSTOM_ANIMATIONS = 1
else
    $(error Unknown CONFIG: $(CONFIG). Use debug, release, minimal, or experimental)
endif

# Convert feature flags to compiler flags
FEATURE_FLAGS = \
    -DMACWMFX_ENABLE_WINDOW_BORDERS=$(ENABLE_WINDOW_BORDERS) \
    -DMACWMFX_ENABLE_WINDOW_SHADOWS=$(ENABLE_WINDOW_SHADOWS) \
    -DMACWMFX_ENABLE_WINDOW_TRANSPARENCY=$(ENABLE_WINDOW_TRANSPARENCY) \
    -DMACWMFX_ENABLE_WINDOW_BLUR=$(ENABLE_WINDOW_BLUR) \
    -DMACWMFX_ENABLE_TITLEBAR_TWEAKS=$(ENABLE_TITLEBAR_TWEAKS) \
    -DMACWMFX_ENABLE_TRAFFIC_LIGHTS=$(ENABLE_TRAFFIC_LIGHTS) \
    -DMACWMFX_ENABLE_RESIZE_LIMITS=$(ENABLE_RESIZE_LIMITS) \
    -DMACWMFX_ENABLE_DOCK_TWEAKS=$(ENABLE_DOCK_TWEAKS) \
    -DMACWMFX_ENABLE_MENUBAR_TWEAKS=$(ENABLE_MENUBAR_TWEAKS) \
    -DMACWMFX_ENABLE_SPACES_TWEAKS=$(ENABLE_SPACES_TWEAKS) \
    -DMACWMFX_ENABLE_ADVANCED_SHADOWS=$(ENABLE_ADVANCED_SHADOWS) \
    -DMACWMFX_ENABLE_CUSTOM_ANIMATIONS=$(ENABLE_CUSTOM_ANIMATIONS)

# =============================================================================
# COMPILER SETTINGS
# =============================================================================

# Architecture support for FAT binary
ARCHS = -arch x86_64 -arch arm64 -arch arm64e

# Compiler flags
CFLAGS = -Wall -Wextra \
    $(CFLAGS_CONFIG) \
    $(FEATURE_FLAGS) \
    $(ARCHS) \
    -fobjc-arc \
    -Wno-deprecated-declarations \
    -I$(SOURCE_DIR) \
    -I$(SOURCE_DIR)/ZKSwizzle \
    -I$(SOURCE_DIR)/headers \
    -I$(SOURCE_DIR)/SymRez \
    -isysroot $(SDKROOT) \
    -iframework $(SDKROOT)/System/Library/Frameworks \
    -F/System/Library/PrivateFrameworks

# Linker flags for dylib
LDFLAGS = -dynamiclib \
    -install_name @rpath/libmacwmfx.dylib \
    -compatibility_version 1.0.0 \
    -current_version 1.0.0 \
    -framework Foundation \
    -framework AppKit \
    -framework CoreGraphics \
    -framework ApplicationServices \
    -framework QuartzCore \
    -isysroot $(SDKROOT) \
    $(ARCHS)

# =============================================================================
# PROJECT SETTINGS
# =============================================================================

# Directories
SOURCE_DIR = src
BUILD_DIR = build

# Target name with configuration suffix
TARGET_NAME = libmacwmfx_$(CONFIG)
TARGET = $(BUILD_DIR)/$(TARGET_NAME).dylib

# Source files (automatically find all .m, .mm, .c, .cpp files)
SOURCES = $(shell find $(SOURCE_DIR) -name "*.m" -o -name "*.c" -o -name "*.mm" -o -name "*.cpp")
OBJECTS = $(SOURCES:$(SOURCE_DIR)/%=$(BUILD_DIR)/%.o)

# =============================================================================
# BUILD TARGETS
# =============================================================================

.PHONY: all clean debug release minimal experimental test install help

# Default target
all: $(TARGET)

# Configuration shortcuts
debug:
	$(MAKE) CONFIG=debug

release:
	$(MAKE) CONFIG=release

minimal:
	$(MAKE) CONFIG=minimal

experimental:
	$(MAKE) CONFIG=experimental

# Main build target
$(TARGET): $(OBJECTS) | $(BUILD_DIR)
	@echo "Linking $(TARGET_NAME).dylib ($(CONFIG) configuration)..."
	$(CC) $(LDFLAGS) -o $@ $(OBJECTS)
	@echo "Build complete: $@"
	@echo ""
	@echo "Enabled features:"
	@echo "  Window Borders: $(ENABLE_WINDOW_BORDERS)"
	@echo "  Window Shadows: $(ENABLE_WINDOW_SHADOWS)"
	@echo "  Window Transparency: $(ENABLE_WINDOW_TRANSPARENCY)"
	@echo "  Window Blur: $(ENABLE_WINDOW_BLUR)"
	@echo "  Titlebar Tweaks: $(ENABLE_TITLEBAR_TWEAKS)"
	@echo "  Traffic Lights: $(ENABLE_TRAFFIC_LIGHTS)"
	@echo "  Resize Limits: $(ENABLE_RESIZE_LIMITS)"
	@echo "  Dock Tweaks: $(ENABLE_DOCK_TWEAKS)"
	@echo "  Menubar Tweaks: $(ENABLE_MENUBAR_TWEAKS)"
	@echo "  Spaces Tweaks: $(ENABLE_SPACES_TWEAKS)"
	@echo "  Advanced Shadows: $(ENABLE_ADVANCED_SHADOWS)"
	@echo "  Custom Animations: $(ENABLE_CUSTOM_ANIMATIONS)"

# Object file compilation rules
$(BUILD_DIR)/%.m.o: $(SOURCE_DIR)/%.m | $(BUILD_DIR)
	@mkdir -p $(dir $@)
	@echo "Compiling $<..."
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD_DIR)/%.c.o: $(SOURCE_DIR)/%.c | $(BUILD_DIR)
	@mkdir -p $(dir $@)
	@echo "Compiling $<..."
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD_DIR)/%.mm.o: $(SOURCE_DIR)/%.mm | $(BUILD_DIR)
	@mkdir -p $(dir $@)
	@echo "Compiling $<..."
	$(CXX) $(CFLAGS) -c $< -o $@

$(BUILD_DIR)/%.cpp.o: $(SOURCE_DIR)/%.cpp | $(BUILD_DIR)
	@mkdir -p $(dir $@)
	@echo "Compiling $<..."
	$(CXX) $(CFLAGS) -c $< -o $@

# Create build directory
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

# Test target
test: debug
	@echo "Testing $(TARGET_NAME).dylib..."
	@if [ -f "$(TARGET)" ]; then \
		echo "✓ Build successful"; \
		file "$(TARGET)"; \
		otool -L "$(TARGET)" | head -10; \
	else \
		echo "✗ Build failed"; \
		exit 1; \
	fi

# Clean build artifacts
clean:
	rm -rf $(BUILD_DIR)
	@echo "Cleaned build directory"

# Install target
install: release
	@echo "Installing to /usr/local/lib/..."
	sudo mkdir -p /usr/local/lib
	sudo cp $(BUILD_DIR)/libmacwmfx_release.dylib /usr/local/lib/libmacwmfx.dylib

# Help target
help:
	@echo "macwmfx Build System"
	@echo "==================="
	@echo ""
	@echo "Build Configurations:"
	@echo "  make debug        - Debug build with all logging"
	@echo "  make release      - Optimized release build"
	@echo "  make minimal      - Minimal build with basic features only"
	@echo "  make experimental - Debug build with experimental features"
	@echo ""
	@echo "Feature Control (can be combined with any config):"
	@echo "  make debug ENABLE_WINDOW_SHADOWS=0    - Disable window shadows"
	@echo "  make release ENABLE_DOCK_TWEAKS=0     - Disable dock tweaks"
	@echo ""
	@echo "Other Targets:"
	@echo "  make test         - Build and test the debug version"
	@echo "  make clean        - Clean build artifacts"
	@echo "  make install      - Install release version system-wide"
	@echo "  make help         - Show this help"
	@echo ""
	@echo "Examples:"
	@echo "  make debug                                    # Debug with all features"
	@echo "  make minimal                                  # Minimal feature set"
	@echo "  make release ENABLE_WINDOW_BLUR=0            # Release without blur"
	@echo "  make experimental                             # All experimental features"
