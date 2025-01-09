# Compiler and flags
CC = clang
CFLAGS = -fobjc-arc -Wall -Wextra -O2 -I$(SOURCE_DIR) -I$(SOURCE_DIR)/ZKSwizzle -I$(SOURCE_DIR)/headers -I$(SOURCE_DIR)/config
ARCHS = -arch x86_64 -arch arm64 -arch arm64e
FRAMEWORKS = -framework Foundation -framework AppKit -framework QuartzCore -F/System/Library/PrivateFrameworks -framework SkyLight

# Project name and paths
PROJECT = macwmfx
DYLIB_NAME = lib$(PROJECT).dylib
CLI_NAME = $(PROJECT)
BUILD_DIR = build
INSTALL_DIR = /usr/local/bin/ammonia/tweaks
CLI_INSTALL_DIR = /usr/local/bin
SOURCE_DIR = macwmfx

# Source files for dylib
DYLIB_SOURCES = $(filter-out $(SOURCE_DIR)/CLITool.m, \
    $(wildcard $(SOURCE_DIR)/*.m) \
    $(wildcard $(SOURCE_DIR)/ZKSwizzle/*.m) \
    $(wildcard $(SOURCE_DIR)/config/*.m) \
    $(wildcard $(SOURCE_DIR)/dock/*.m) \
    $(wildcard $(SOURCE_DIR)/menubar/*.m) \
    $(wildcard $(SOURCE_DIR)/spaces/*.m) \
    $(wildcard $(SOURCE_DIR)/windows/*.m) \
    $(wildcard $(SOURCE_DIR)/windows/*/*.m))

DYLIB_OBJECTS = $(DYLIB_SOURCES:$(SOURCE_DIR)/%.m=$(BUILD_DIR)/%.o)

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

# Link dylib
$(BUILD_DIR)/$(DYLIB_NAME): $(DYLIB_OBJECTS)
	$(CC) -v $(DYLIB_FLAGS) $(ARCHS) $(DYLIB_OBJECTS) -o $@ $(FRAMEWORKS)

# Build CLI tool
$(BUILD_DIR)/$(CLI_NAME): $(CLI_SOURCE) $(BUILD_DIR)/$(DYLIB_NAME)
	$(CC) $(CFLAGS) $(ARCHS) $(CLI_SOURCE) $(BUILD_DIR)/$(DYLIB_NAME) -o $@ $(FRAMEWORKS) -Wl,-rpath,$(INSTALL_DIR) -fvisibility=default

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