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
    -I$(SOURCE_DIR) \
    -I$(SOURCE_DIR)/ZKSwizzle \
    -I$(SOURCE_DIR)/headers \
    -I$(SOURCE_DIR)/config \
    -I$(SOURCE_DIR)/SymRez \
    -isysroot $(SDKROOT) \
    -iframework $(SDKROOT)/System/Library/Frameworks \
    -F/System/Library/PrivateFrameworks

# Add C++ specific flags
CXXFLAGS = $(CFLAGS) -stdlib=libc++ \
    -I$(SDKROOT)/usr/include/c++/v1 \
    -I$(SDKROOT)/usr/include \
    -I/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/include/c++/v1

ARCHS = -arch x86_64 -arch arm64 -arch arm64e

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
    $(filter-out $(SOURCE_DIR)/CLITool.m, \
    $(wildcard $(SOURCE_DIR)/*.m) \
    $(wildcard $(SOURCE_DIR)/ZKSwizzle/*.m) \
    $(wildcard $(SOURCE_DIR)/config/*.m) \
    $(wildcard $(SOURCE_DIR)/dock/*.m) \
    $(wildcard $(SOURCE_DIR)/menubar/*.m) \
    $(wildcard $(SOURCE_DIR)/spaces/*.m) \
    $(wildcard $(SOURCE_DIR)/windows/*.m) \
    $(wildcard $(SOURCE_DIR)/windows/windowTitlebar/*.m) \
    $(wildcard $(SOURCE_DIR)/windows/windowShadow/*.m)))

# Collect MM files separately
MM_SOURCES = $(sort \
    $(wildcard $(SOURCE_DIR)/windows/windowShadow/*.mm))

# Update object files to include both .m and .mm sources
DYLIB_OBJECTS = $(DYLIB_SOURCES:$(SOURCE_DIR)/%.m=$(BUILD_DIR)/%.o) \
    $(MM_SOURCES:$(SOURCE_DIR)/%.mm=$(BUILD_DIR)/%.o) \
    $(SWIFT_OBJECTS)

# CLI tool source and object
CLI_SOURCE = $(SOURCE_DIR)/CLITool.m
CLI_OBJECT = $(BUILD_DIR)/CLITool.o

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
              -fvisibility=default

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
    -framework CoreFoundation -framework CoreImage -framework IOKit -framework IOSurface

PRIVATE_FRAMEWORKS = -framework SkyLight

# Default target
all: $(BUILD_DIR)/$(DYLIB_NAME) $(BUILD_DIR)/$(CLI_NAME)

# Create build directory and subdirectories
$(BUILD_DIR):
	@mkdir -p $(BUILD_DIR)
	@mkdir -p $(BUILD_DIR)/ZKSwizzle
	@mkdir -p $(BUILD_DIR)/config
	@mkdir -p $(BUILD_DIR)/dock
	@mkdir -p $(BUILD_DIR)/menubar
	@mkdir -p $(BUILD_DIR)/spaces
	@mkdir -p $(BUILD_DIR)/windows
	@mkdir -p $(BUILD_DIR)/windows/windowTrafficLights

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
	$(CC) $(CFLAGS) $(ARCHS) -c $< -o $@

# Add Swift compilation rule
$(BUILD_DIR)/%.o: $(SOURCE_DIR)/%.swift | $(BUILD_DIR)
	@mkdir -p $(dir $@)
	$(SWIFTC) -I./SymRez -c $< -o $@

# Link dylib
$(BUILD_DIR)/$(DYLIB_NAME): $(DYLIB_OBJECTS)
	$(CXX) $(DYLIB_FLAGS) $(ARCHS) $(DYLIB_OBJECTS) -o $@ \
	-F$(FRAMEWORK_PATH) \
	-F$(PRIVATE_FRAMEWORK_PATH) \
	-F/System/Library/PrivateFrameworks \
	$(PUBLIC_FRAMEWORKS) \
	$(PRIVATE_FRAMEWORKS) \
	-L$(SDKROOT)/usr/lib \
	-L/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib \
	-L/usr/lib \
	-stdlib=libc++

# Build CLI tool
$(BUILD_DIR)/$(CLI_NAME): $(CLI_SOURCE) $(BUILD_DIR)/$(DYLIB_NAME)
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
	$(CLI_SOURCE) $(BUILD_DIR)/$(DYLIB_NAME) \
	$(PUBLIC_FRAMEWORKS) \
	$(PRIVATE_FRAMEWORKS) \
	-framework Foundation \
	-framework AppKit \
	-framework QuartzCore \
	-framework Cocoa \
	-framework CoreFoundation \
	-framework SkyLight \
	-Wl,-rpath,$(INSTALL_DIR) \
	-fvisibility=default \
	-o $@

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