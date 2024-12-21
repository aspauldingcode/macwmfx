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
	@echo "Quitting test applications..."
	@killall "Spotify" 2>/dev/null || true
	@killall "System Settings" 2>/dev/null || true
	@killall "Chess" 2>/dev/null || true
	@killall "LibreOffice" 2>/dev/null || true
	@killall "Brave Browser" 2>/dev/null || true
	@killall "Beeper" 2>/dev/null || true
	@killall "Safari" 2>/dev/null || true
	@killall "Finder" 2>/dev/null && sleep 2 && open -a "Finder" || true
	@echo "Relaunching test applications..."
	@open -a "Spotify"
	@open -a "System Settings"
	@open -a "Chess"
	@open -a "LibreOffice"
	@open -a "Brave Browser"
	@open -a "Beeper"
	@open -a "Safari"
	@echo "Test applications relaunched"

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