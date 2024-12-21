# Compiler and flags
CC = clang
CFLAGS = -fobjc-arc -Wall -Wextra -O2 -I$(SOURCE_DIR) -I$(SOURCE_DIR)/ZKSwizzle
FRAMEWORKS = -framework Foundation -framework AppKit -framework QuartzCore

# Project name and paths
PROJECT = macwmfx
DYLIB_NAME = lib$(PROJECT).dylib
BUILD_DIR = build
INSTALL_DIR = /usr/local/bin/ammonia/tweaks
SOURCE_DIR = macwmfx

# Source files
SOURCES = $(wildcard $(SOURCE_DIR)/*.m) $(wildcard $(SOURCE_DIR)/ZKSwizzle/*.m)
OBJECTS = $(SOURCES:$(SOURCE_DIR)/%.m=$(BUILD_DIR)/%.o)

# Installation targets
INSTALL_PATH = $(INSTALL_DIR)/$(DYLIB_NAME)
BLACKLIST_SOURCE = libmacwmfx.dylib.blacklist
BLACKLIST_DEST = $(INSTALL_DIR)/libmacwmfx.dylib.blacklist

# Dylib settings
DYLIB_FLAGS = -dynamiclib \
              -install_name @rpath/$(DYLIB_NAME) \
              -compatibility_version 1.0.0 \
              -current_version 1.0.0

# Default target
all: $(BUILD_DIR)/$(DYLIB_NAME)

# Create build directory and subdirectories
$(BUILD_DIR):
	@mkdir -p $(BUILD_DIR)
	@mkdir -p $(BUILD_DIR)/ZKSwizzle

# Compile source files
$(BUILD_DIR)/%.o: $(SOURCE_DIR)/%.m | $(BUILD_DIR)
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -c $< -o $@

# Link dylib
$(BUILD_DIR)/$(DYLIB_NAME): $(OBJECTS)
	$(CC) $(DYLIB_FLAGS) $(OBJECTS) -o $@ $(FRAMEWORKS)

# Install the dylib and blacklist
install: $(BUILD_DIR)/$(DYLIB_NAME)
	@sudo mkdir -p $(INSTALL_DIR)
	@sudo cp $< $(INSTALL_PATH)
	@sudo chmod 755 $(INSTALL_PATH)
	@if [ -f $(BLACKLIST_SOURCE) ]; then \
		sudo cp $(BLACKLIST_SOURCE) $(BLACKLIST_DEST); \
		sudo chmod 644 $(BLACKLIST_DEST); \
		echo "Installed $(DYLIB_NAME) and blacklist to $(INSTALL_DIR)"; \
	else \
		echo "Warning: $(BLACKLIST_SOURCE) not found"; \
		echo "Installed $(DYLIB_NAME) to $(INSTALL_PATH)"; \
	fi

# Test target that builds, installs, and relaunches test applications
test: install
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
	@log show --predicate 'subsystem == "com.aspauldingcode.macwmfx"' --debug --last 5m || true

# Clean build files
clean:
	@rm -rf $(BUILD_DIR)
	@echo "Cleaned build directory"

# Delete installed files
delete:
	@sudo rm -f $(INSTALL_PATH)
	@sudo rm -f $(BLACKLIST_DEST)
	@echo "Deleted $(DYLIB_NAME) and blacklist from $(INSTALL_DIR)"

# Uninstall
uninstall:
	@sudo rm -f $(INSTALL_PATH)
	@sudo rm -f $(BLACKLIST_DEST)
	@echo "Uninstalled $(DYLIB_NAME) and blacklist"

.PHONY: all clean install uninstall test delete