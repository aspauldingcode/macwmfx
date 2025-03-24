# Dynamic compiler detection
XCODE_PATH := $(shell xcode-select -p)
XCODE_TOOLCHAIN := $(XCODE_PATH)/Toolchains/XcodeDefault.xctoolchain
CC := $(shell xcrun -find clang)
CXX := $(shell xcrun -find clang++)

# SDK paths (already dynamic, but grouped here for clarity)
SDKROOT ?= $(shell xcrun --show-sdk-path)
ISYSROOT := $(shell xcrun -sdk macosx --show-sdk-path)
INCLUDE_PATH := $(shell xcrun -sdk macosx --show-sdk-platform-path)/Developer/SDKs/MacOSX.sdk/usr/include

# Compiler and flags
CFLAGS = -Wall -Wextra -O2 \
    -fobjc-arc \
    -Wno-deprecated-declarations \
    -I$(SOURCE_DIR) \
    -I$(SOURCE_DIR)/ZKSwizzle \
    -I$(SOURCE_DIR)/headers \
    -I$(SOURCE_DIR)/config \
    -I$(SOURCE_DIR)/SymRez \
    -isysroot $(SDKROOT) \
    -iframework $(SDKROOT)/System/Library/Frameworks \
    -F/System/Library/PrivateFrameworks \
    -I$(SDKROOT)/usr/include \
    -fmodules \
    -mmacosx-version-min=15.0 \
    -fobjc-arc \
    -fexceptions \
    -fvisibility=hidden \
    -Wno-implicit-function-declaration

# Add C++ specific flags
CXXFLAGS = $(CFLAGS) -stdlib=libc++ \
    -I$(SDKROOT)/usr/include/c++/v1 \
    -I$(SDKROOT)/usr/include \
    -I$(XCODE_TOOLCHAIN)/usr/include/c++/v1 \
	-Wno-implicit-function-declaration

ARCHS = -arch x86_64 -arch arm64 -arch arm64e

# Linker flags
LDFLAGS = -Wl,-U,_inject_entry -framework Foundation -framework IOSurface \
    -Wl,-U,_SLWindowServerShadowData \
    -Wl,-U,_SLSSetWindowShadowProperties \
    -Wl,-U,_SLSWindowSetShadowProperties
	
# Project name and paths
PROJECT = macwmfx
DYLIB_NAME = lib$(PROJECT).dylib
CLI_NAME = $(PROJECT)
BUILD_DIR = build
INSTALL_DIR = /usr/local/bin/ammonia/tweaks
CLI_INSTALL_DIR = /usr/local/bin
SOURCE_DIR = macwmfx

# Update source file collection to avoid duplicates
DYLIB_SOURCES = $(sort \
    $(filter-out $(SOURCE_DIR)/CLITool.m $(SOURCE_DIR)/SymRez/SymRez.c \
		$(SOURCE_DIR)/windows/windowShadow/ShadowColor.m \
		$(SOURCE_DIR)/objc_hook.m, \
        $(SOURCE_DIR)/ZKSwizzle/ZKSwizzle.m \
        $(wildcard $(SOURCE_DIR)/*.m) \
        $(wildcard $(SOURCE_DIR)/config/*.m) \
        $(wildcard $(SOURCE_DIR)/dock/*.m) \
        $(wildcard $(SOURCE_DIR)/menubar/*.m) \
        $(wildcard $(SOURCE_DIR)/spaces/*.m) \
        $(wildcard $(SOURCE_DIR)/windows/windowAnimations/*.m) \
        $(wildcard $(SOURCE_DIR)/windows/windowBehavior/*.m) \
        $(wildcard $(SOURCE_DIR)/windows/windowBlur/*.m) \
        $(wildcard $(SOURCE_DIR)/windows/windowMaskShapes/*.m) \
        $(wildcard $(SOURCE_DIR)/windows/windowOutline/*.m) \
        $(wildcard $(SOURCE_DIR)/windows/windowShadow/*.m) \
        $(wildcard $(SOURCE_DIR)/windows/windowSizeContraints/*.m) \
        $(wildcard $(SOURCE_DIR)/windows/windowTitlebar/*.m) \
        $(wildcard $(SOURCE_DIR)/windows/windowTrafficLights/*.m) \
        $(wildcard $(SOURCE_DIR)/windows/windowTransparency/*.m)))

# Collect MM files separately
MM_SOURCES = $(sort \
    $(wildcard $(SOURCE_DIR)/windows/windowOutline/*.mm) \
    $(wildcard $(SOURCE_DIR)/windows/windowShadow/*.mm))

# Update object files to include both .m and .mm sources
DYLIB_OBJECTS = $(DYLIB_SOURCES:$(SOURCE_DIR)/%.m=$(BUILD_DIR)/%.o) \
    $(MM_SOURCES:$(SOURCE_DIR)/%.mm=$(BUILD_DIR)/%.o) \
    $(BUILD_DIR)/SymRez/SymRez.o \
    $(SWIFT_OBJECTS)

# CLI tool source and object - update to include config files
CLI_SOURCES = $(SOURCE_DIR)/CLITool.m $(wildcard $(SOURCE_DIR)/config/*.m)
CLI_OBJECTS = $(CLI_SOURCES:$(SOURCE_DIR)/%.m=$(BUILD_DIR)/%.o)

# Installation targets
INSTALL_PATH = $(INSTALL_DIR)/$(DYLIB_NAME)
CLI_INSTALL_PATH = $(CLI_INSTALL_DIR)/$(CLI_NAME)
BLACKLIST_SOURCE = libmacwmfx.dylib.blacklist
BLACKLIST_DEST = $(INSTALL_DIR)/libmacwmfx.dylib.blacklist

# Dylib settings
DYLIB_FLAGS = -dynamiclib \
    -install_name @rpath/$(DYLIB_NAME) \
    -compatibility_version 1.0.0 \
    -current_version 1.0.0 \
    -fvisibility=default \
    -mmacosx-version-min=15.0 \
    -all_load \
    -Wl,-export_dynamic

# Link dylib (single definition)
$(BUILD_DIR)/$(DYLIB_NAME): $(DYLIB_OBJECTS)
	$(CXX) $(DYLIB_FLAGS) $(ARCHS) \
	-isysroot $(SDKROOT) \
	-I$(SDKROOT)/usr/include \
	-I$(SOURCE_DIR) \
	-I$(SOURCE_DIR)/headers \
	-I$(SOURCE_DIR)/SymRez \
	-I$(XCODE_TOOLCHAIN)/usr/include \
	-I$(XCODE_TOOLCHAIN)/usr/lib/clang/15.0.0/include \
	$(DYLIB_OBJECTS) -o $@ \
	-F$(FRAMEWORK_PATH) \
	-F$(PRIVATE_FRAMEWORK_PATH) \
	-F/System/Library/PrivateFrameworks \
	$(PUBLIC_FRAMEWORKS) \
	$(PRIVATE_FRAMEWORKS) \
	-L$(SDKROOT)/usr/lib \
	-L$(XCODE_TOOLCHAIN)/usr/lib \
	-L/usr/lib \
	-L/Library/wsfun \
	-stdlib=libc++ \
	$(LDFLAGS)

# Add Swift compiler
SWIFTC = swiftc

# Add Swift sources (excluding Package.swift)
SWIFT_SOURCES = $(filter-out Package.swift, $(wildcard $(SOURCE_DIR)/*.swift))
SWIFT_OBJECTS = $(SWIFT_SOURCES:$(SOURCE_DIR)/%.swift=$(BUILD_DIR)/%.o)

# Update framework paths to use dynamic SDK root
FRAMEWORK_PATH = $(SDKROOT)/System/Library/Frameworks
PRIVATE_FRAMEWORK_PATH = $(SDKROOT)/System/Library/PrivateFrameworks

# Split frameworks into public and private, adding IOKit and IOSurface
PUBLIC_FRAMEWORKS = -framework Foundation -framework AppKit -framework QuartzCore -framework Cocoa \
    -framework CoreFoundation -framework CoreImage -framework IOKit -framework IOSurface \
    -framework CoreGraphics

PRIVATE_FRAMEWORKS = -framework SkyLight

# Default target
all: $(BUILD_DIR)/$(DYLIB_NAME) $(BUILD_DIR)/$(CLI_NAME)

# Create build directory and subdirectories
$(BUILD_DIR):
	@mkdir -p $(BUILD_DIR)
	@mkdir -p $(BUILD_DIR)/config
	@mkdir -p $(BUILD_DIR)/dock
	@mkdir -p $(BUILD_DIR)/menubar
	@mkdir -p $(BUILD_DIR)/spaces
	@mkdir -p $(BUILD_DIR)/windows/windowAnimations
	@mkdir -p $(BUILD_DIR)/windows/windowBehavior
	@mkdir -p $(BUILD_DIR)/windows/windowBlur
	@mkdir -p $(BUILD_DIR)/windows/windowMaskShapes
	@mkdir -p $(BUILD_DIR)/windows/windowOutline
	@mkdir -p $(BUILD_DIR)/windows/windowShadow
	@mkdir -p $(BUILD_DIR)/windows/windowSizeContraints
	@mkdir -p $(BUILD_DIR)/windows/windowTitlebar
	@mkdir -p $(BUILD_DIR)/windows/windowTrafficLights
	@mkdir -p $(BUILD_DIR)/windows/windowTransparency
	@mkdir -p $(BUILD_DIR)/SymRez

# Compile source files
$(BUILD_DIR)/%.o: $(SOURCE_DIR)/%.m | $(BUILD_DIR)
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) $(ARCHS) -c $< -o $@

$(BUILD_DIR)/%.o: $(SOURCE_DIR)/%.mm | $(BUILD_DIR)
	@mkdir -p $(dir $@)
	$(CXX) $(CXXFLAGS) $(ARCHS) -fmodules -c $< -o $@

$(BUILD_DIR)/%.o: $(SOURCE_DIR)/%.cpp | $(BUILD_DIR)
	@mkdir -p $(dir $@)
	$(CXX) $(CXXFLAGS) $(ARCHS) -c $< -o $@

$(BUILD_DIR)/%.o: $(SOURCE_DIR)/%.c | $(BUILD_DIR)
	@mkdir -p $(dir $@)
	$(CC) -Wall -Wextra -O2 $(ARCHS) \
	-isysroot $(SDKROOT) \
	-I$(SDKROOT)/usr/include \
	-I$(SOURCE_DIR) \
	-I$(SOURCE_DIR)/headers \
	-I$(SOURCE_DIR)/SymRez \
	-I$(XCODE_TOOLCHAIN)/usr/include \
	-I$(XCODE_TOOLCHAIN)/usr/lib/clang/15.0.0/include \
	-c $< -o $@

# Add Swift compilation rule
$(BUILD_DIR)/%.o: $(SOURCE_DIR)/%.swift | $(BUILD_DIR)
	@mkdir -p $(dir $@)
	$(SWIFTC) -I./SymRez -c $< -o $@

# Build CLI tool - update to compile sources first
$(BUILD_DIR)/$(CLI_NAME): $(CLI_OBJECTS) $(BUILD_DIR)/$(DYLIB_NAME)
	$(CC) $(CFLAGS) $(ARCHS) \
	-fmodules \
	-I$(SOURCE_DIR)/SymRez \
	-isysroot $(SDKROOT) \
	-I$(SDKROOT)/System/Library/Frameworks/AppKit.framework/Headers \
	-I$(SDKROOT)/System/Library/Frameworks/Foundation.framework/Headers \
	-iframework $(SDKROOT)/System/Library/Frameworks \
	-F$(FRAMEWORK_PATH) \
	-F$(PRIVATE_FRAMEWORK_PATH) \
	-F/System/Library/PrivateFrameworks \
	$(CLI_OBJECTS) \
	-L$(BUILD_DIR) -lmacwmfx \
	$(PUBLIC_FRAMEWORKS) \
	$(PRIVATE_FRAMEWORKS) \
	-framework Foundation \
	-framework AppKit \
	-framework QuartzCore \
	-framework Cocoa \
	-framework CoreFoundation \
	-framework CoreGraphics \
	-framework IOSurface \
	-framework SkyLight \
	-Wl,-rpath,$(INSTALL_DIR) \
	-fvisibility=default \
	-o $@ \
	$(LDFLAGS)

# Install the dylib, CLI tool, and blacklist
install: $(BUILD_DIR)/$(DYLIB_NAME) $(BUILD_DIR)/$(CLI_NAME)
	@sudo mkdir -p $(INSTALL_DIR)
	@sudo cp $(BUILD_DIR)/$(DYLIB_NAME) $(INSTALL_PATH)
	@sudo chmod 755 $(INSTALL_PATH)
	@sudo cp $(BUILD_DIR)/$(CLI_NAME) $(CLI_INSTALL_PATH)
	@sudo chmod 755 $(CLI_INSTALL_PATH)
	@if [ -f $(BLACKLIST_SOURCE) ]; then \
		sudo cp $(BLACKLIST_SOURCE) $(BLACKLIST_DEST); \
		sudo chmod 644 $(BLACKLIST_DEST); \
		echo "Installed $(DYLIB_NAME), $(CLI_NAME), and blacklist"; \
	else \
		echo "Warning: $(BLACKLIST_SOURCE) not found"; \
		echo "Installed $(DYLIB_NAME) and $(CLI_NAME)"; \
	fi

# Just install existing binaries without building
install-only:
	@if [ ! -f $(BUILD_DIR)/$(DYLIB_NAME) ]; then \
		echo "Error: $(DYLIB_NAME) not found in build directory. Please build first."; \
		exit 1; \
	fi
	@if [ ! -f $(BUILD_DIR)/$(CLI_NAME) ]; then \
		echo "Error: $(CLI_NAME) not found in build directory. Please build first."; \
		exit 1; \
	fi
	@sudo mkdir -p $(INSTALL_DIR)
	@sudo cp $(BUILD_DIR)/$(DYLIB_NAME) $(INSTALL_PATH)
	@sudo chmod 755 $(INSTALL_PATH)
	@sudo cp $(BUILD_DIR)/$(CLI_NAME) $(CLI_INSTALL_PATH)
	@sudo chmod 755 $(CLI_INSTALL_PATH)
	@if [ -f $(BLACKLIST_SOURCE) ]; then \
		sudo cp $(BLACKLIST_SOURCE) $(BLACKLIST_DEST); \
		sudo chmod 644 $(BLACKLIST_DEST); \
		echo "Installed $(DYLIB_NAME), $(CLI_NAME), and blacklist"; \
	else \
		echo "Warning: $(BLACKLIST_SOURCE) not found"; \
		echo "Installed $(DYLIB_NAME) and $(CLI_NAME)"; \
	fi

# Test target that builds, installs, and relaunches test applications
test: install
	@echo "Clearing previous logs..."
	@sudo log erase --all
	@echo "Force quitting test applications..."
	@pkill -9 "Spotify" 2>/dev/null || true
	@pkill -9 "System Settings" 2>/dev/null || true
	@pkill -9 "Chess" 2>/dev/null || true
	@pkill -9 "soffice" 2>/dev/null || true
	@pkill -9 "Brave Browser" 2>/dev/null || true
	@pkill -9 "Beeper" 2>/dev/null || true
	@pkill -9 "Safari" 2>/dev/null || true
	@pkill -9 "Finder" 2>/dev/null && sleep 2 && open -a "Finder" || true
	@echo "Restarting ammonia injector..."
	@sudo pkill -9 ammonia || true
	@sleep 2
	@sudo launchctl bootout system /Library/LaunchDaemons/com.bedtime.ammonia.plist 2>/dev/null || true
	@sleep 2
	@sudo launchctl bootstrap system /Library/LaunchDaemons/com.bedtime.ammonia.plist
	@sleep 2
	@echo "Ammonia injector restarted"
	@echo "Waiting for system to stabilize..."
	@sleep 5
	@echo "Launching test applications..."
	@open -a "Spotify" || echo "Failed to open Spotify"
	@sleep 1
	@open -a "System Settings" || echo "Failed to open System Settings"
	@sleep 1
	@open -a "Chess" || echo "Failed to open Chess"
	@sleep 1
	@open -a "LibreOffice" || echo "Failed to open LibreOffice"
	@sleep 1
	@open -a "Brave Browser" || echo "Failed to open Brave Browser"
	@sleep 1
	@open -a "Beeper" || echo "Failed to open Beeper"
	@sleep 1
	@open -a "Safari" || echo "Failed to open Safari"
	@sleep 1
	@echo "Test applications launched"
	@echo "Checking logs..."
	@log show --predicate 'subsystem == "com.aspauldingcode.macwmfx"' --debug --last 5m > test_output.log || true
	@echo "Checking log for specific entries..."
	@grep "Loaded" test_output.log || echo "No relevant log entries found."

# Clean build files
clean:
	@rm -rf $(BUILD_DIR)
	@echo "Cleaned build directory"

# Delete installed files
delete:
	@echo "Force quitting test applications..."
	@pkill -9 "Spotify" 2>/dev/null || true
	@pkill -9 "System Settings" 2>/dev/null || true
	@pkill -9 "Chess" 2>/dev/null || true
	@pkill -9 "soffice" 2>/dev/null || true
	@pkill -9 "Brave Browser" 2>/dev/null || true
	@pkill -9 "Beeper" 2>/dev/null || true
	@pkill -9 "Safari" 2>/dev/null || true
	@pkill -9 "Finder" 2>/dev/null && sleep 2 && open -a "Finder" || true
	@sudo rm -f $(INSTALL_PATH)
	@sudo rm -f $(CLI_INSTALL_PATH)
	@sudo rm -f $(BLACKLIST_DEST)
	@echo "Deleted $(DYLIB_NAME), $(CLI_NAME), and blacklist"

# Uninstall
uninstall:
	@sudo rm -f $(INSTALL_PATH)
	@sudo rm -f $(CLI_INSTALL_PATH)
	@sudo rm -f $(BLACKLIST_DEST)
	@echo "Uninstalled $(DYLIB_NAME), $(CLI_NAME), and blacklist"

.PHONY: all clean install install-only uninstall test delete
