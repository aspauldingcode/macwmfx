# macwmfx Build System - Modular Architecture
# ===========================================

# Color definitions for output (use echo -e for proper interpretation)
GREEN := \033[32m
YELLOW := \033[33m
BLUE := \033[34m
RED := \033[31m
CYAN := \033[36m
BOLD := \033[1m
RESET := \033[0m

# Check if colors are supported
ifneq ($(findstring xterm,$(TERM)),)
    # Terminal supports colors
    COLOR_SUPPORT := 1
else
    # Disable colors for non-color terminals
    COLOR_SUPPORT := 0
endif

# Color functions
ifeq ($(COLOR_SUPPORT),1)
    define color_echo
        @echo -e "$(1)$(2)$(RESET)"
    endef
else
    define color_echo
        @echo "$(2)"
    endef
endif

# Dynamic compiler detection
XCODE_PATH := $(shell xcode-select -p)
CC := $(shell xcrun -find clang)
CXX := $(shell xcrun -find clang++)

# SDK paths
SDKROOT ?= $(shell xcrun --show-sdk-path)

# =============================================================================
# BUILD CONFIGURATION
# =============================================================================

# Build configuration (debug, release, minimal)
CONFIG ?= debug

# Configuration-specific flags
ifeq ($(CONFIG),debug)
    CFLAGS_CONFIG = -DDEBUG=1 -g -O0
    MACWMFX_VERBOSE_LOGGING = 1
else ifeq ($(CONFIG),release)
    CFLAGS_CONFIG = -DNDEBUG=1 -O2
    MACWMFX_VERBOSE_LOGGING = 0
else ifeq ($(CONFIG),minimal)
    CFLAGS_CONFIG = -DNDEBUG=1 -O2
    MACWMFX_VERBOSE_LOGGING = 0
else
    $(error $(RED)Unknown CONFIG: $(CONFIG). Use debug, release, or minimal$(RESET))
endif

# ALWAYS enable debugging for macwmfx regardless of build configuration
MACWMFX_DEBUG = 1

# Test apps for the test command
TEST_APPS = Finder Safari "System Preferences" Calculator TextEdit

# =============================================================================
# COMPILER SETTINGS
# =============================================================================

# Architecture support for FAT binary
ARCHS = -arch x86_64 -arch arm64 -arch arm64e

# Compiler flags
CFLAGS = -Wall -Wextra \
    $(CFLAGS_CONFIG) \
    -DMACWMFX_DEBUG=$(MACWMFX_DEBUG) \
    -DMACWMFX_VERBOSE_LOGGING=$(MACWMFX_VERBOSE_LOGGING) \
    $(ARCHS) \
    -fobjc-arc \
    -Wno-deprecated-declarations \
    -I$(SOURCE_DIR) \
    -I$(SOURCE_DIR)/shared/headers \
    -I$(SOURCE_DIR)/shared/ZKSwizzle \
    -I$(SOURCE_DIR)/SymRez \
    -I$(SOURCE_DIR)/core \
    -I$(SOURCE_DIR)/core/utils \
    -I$(SOURCE_DIR)/core/types \
    -I$(SOURCE_DIR)/modules \
    -I$(SOURCE_DIR)/modules/windows \
    -I$(SOURCE_DIR)/modules/dock \
    -I$(SOURCE_DIR)/modules/menubar \
    -I$(SOURCE_DIR)/modules/spaces \
    -I$(SOURCE_DIR)/server \
    -I$(SOURCE_DIR)/client \
    -isysroot $(SDKROOT) \
    -iframework $(SDKROOT)/System/Library/Frameworks \
    -F/System/Library/PrivateFrameworks

# Linker flags for main dylib
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

# Linker flags for server dylib
LDFLAGS_SERVER = -dynamiclib \
    -install_name @rpath/libmacwmfx_server.dylib \
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

# Target names with configuration suffix
TARGET_NAME = libmacwmfx_$(CONFIG)
SERVER_TARGET_NAME = libmacwmfx_server_$(CONFIG)
TARGET = $(BUILD_DIR)/$(TARGET_NAME).dylib
SERVER_TARGET = $(BUILD_DIR)/$(SERVER_TARGET_NAME).dylib

# CLI tool target
CLI_TARGET = $(BUILD_DIR)/macwmfx

# Source files (automatically find all .m, .mm, .c, .cpp files)
SOURCES = $(shell find $(SOURCE_DIR) -name "*.m" -o -name "*.c" -o -name "*.mm" -o -name "*.cpp" ! -name "CLITool.m" ! -path "*/server/*")
OBJECTS = $(SOURCES:$(SOURCE_DIR)/%=$(BUILD_DIR)/%.o)

# Server source files
SERVER_SOURCES = $(shell find $(SOURCE_DIR)/server -name "*.m" -o -name "*.c" -o -name "*.mm" -o -name "*.cpp")
SERVER_OBJECTS = $(SERVER_SOURCES:$(SOURCE_DIR)/%=$(BUILD_DIR)/%.o)

# CLI tool source
CLI_SOURCE = $(SOURCE_DIR)/modules/CLITool.m
CLI_OBJECT = $(BUILD_DIR)/modules/CLITool.m.o

# =============================================================================
# BUILD TARGETS
# =============================================================================

.PHONY: all clean debug release minimal test install help cli server fund

# Default target
all: $(TARGET) $(SERVER_TARGET) $(CLI_TARGET)

# Configuration shortcuts
debug:
	$(call color_echo,$(BLUE)$(BOLD),Building debug configuration...)
	$(MAKE) CONFIG=debug

release:
	$(call color_echo,$(BLUE)$(BOLD),Building release configuration...)
	$(MAKE) CONFIG=release

minimal:
	$(call color_echo,$(BLUE)$(BOLD),Building minimal configuration...)
	$(MAKE) CONFIG=minimal

# CLI tool target
cli: $(CLI_TARGET)

# Server target
server: $(SERVER_TARGET)

# Main build target
$(TARGET): $(OBJECTS) | $(BUILD_DIR)
	$(call color_echo,$(BLUE)$(BOLD),Linking $(TARGET_NAME).dylib ($(CONFIG) configuration)...)
	$(CC) $(LDFLAGS) -o $@ $(OBJECTS)
	$(call color_echo,$(GREEN)$(BOLD),✓ Build complete: $@)
	@echo ""
	$(call color_echo,$(YELLOW),Build Configuration: $(CONFIG))
	$(call color_echo,$(YELLOW),Debug Mode: $(MACWMFX_DEBUG) (ALWAYS ENABLED))
	$(call color_echo,$(YELLOW),Verbose Logging: $(MACWMFX_VERBOSE_LOGGING))
	@echo ""
	$(call color_echo,$(CYAN),Source files compiled:)
	@echo "$(SOURCES)" | tr ' ' '\n' | sed 's|$(SOURCE_DIR)/||' | sort

# Server build target
$(SERVER_TARGET): $(SERVER_OBJECTS) | $(BUILD_DIR)
	$(call color_echo,$(BLUE)$(BOLD),Linking $(SERVER_TARGET_NAME).dylib ($(CONFIG) configuration)...)
	$(CC) $(LDFLAGS_SERVER) -o $@ $(SERVER_OBJECTS)
	$(call color_echo,$(GREEN)$(BOLD),✓ Server build complete: $@)
	@echo ""
	$(call color_echo,$(YELLOW),Server Configuration: $(CONFIG))
	$(call color_echo,$(YELLOW),Debug Mode: $(MACWMFX_DEBUG) (ALWAYS ENABLED))
	$(call color_echo,$(YELLOW),Verbose Logging: $(MACWMFX_VERBOSE_LOGGING))

# Object file compilation rules
$(BUILD_DIR)/%.m.o: $(SOURCE_DIR)/%.m | $(BUILD_DIR)
	@mkdir -p $(dir $@)
	$(call color_echo,$(BLUE),Compiling $<...)
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD_DIR)/%.c.o: $(SOURCE_DIR)/%.c | $(BUILD_DIR)
	@mkdir -p $(dir $@)
	$(call color_echo,$(BLUE),Compiling $<...)
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD_DIR)/%.mm.o: $(SOURCE_DIR)/%.mm | $(BUILD_DIR)
	@mkdir -p $(dir $@)
	$(call color_echo,$(BLUE),Compiling $<...)
	$(CXX) $(CFLAGS) -c $< -o $@

$(BUILD_DIR)/%.cpp.o: $(SOURCE_DIR)/%.cpp | $(BUILD_DIR)
	@mkdir -p $(dir $@)
	$(call color_echo,$(BLUE),Compiling $<...)
	$(CXX) $(CFLAGS) -c $< -o $@

# Create build directory
$(BUILD_DIR):
	$(call color_echo,$(BLUE),Creating build directory...)
	mkdir -p $(BUILD_DIR)

# Test target - builds debug version, installs it, and opens test apps
test: debug
	$(call color_echo,$(BLUE)$(BOLD),Testing macwmfx with debug build...)
	@if [ -f "$(TARGET)" ]; then \
		echo -e "$(GREEN)$(BOLD)✓ Build successful$(RESET)"; \
		file "$(TARGET)"; \
		otool -L "$(TARGET)" | head -10; \
		echo ""; \
		echo -e "$(CYAN)Symbols exported:$(RESET)"; \
		nm -D "$(TARGET)" | grep -E "(macwmfx)" | head -5; \
	else \
		echo -e "$(RED)$(BOLD)✗ Build failed$(RESET)"; \
		exit 1; \
	fi
	@echo ""
	$(call color_echo,$(BLUE)$(BOLD),Testing $(SERVER_TARGET_NAME).dylib...)
	@if [ -f "$(SERVER_TARGET)" ]; then \
		echo -e "$(GREEN)$(BOLD)✓ Server build successful$(RESET)"; \
		file "$(SERVER_TARGET)"; \
		otool -L "$(SERVER_TARGET)" | head -10; \
	else \
		echo -e "$(RED)$(BOLD)✗ Server build failed$(RESET)"; \
		exit 1; \
	fi
	@echo ""
	$(call color_echo,$(BLUE)$(BOLD),Installing debug version for testing...)
	$(call color_echo,$(YELLOW),Creating directories...)
	@sudo mkdir -p /usr/local/lib /usr/local/bin /private/var/ammonia/core/tweaks
	$(call color_echo,$(YELLOW),Installing debug dylib to /private/var/ammonia/core/tweaks/...)
	@sudo cp $(BUILD_DIR)/libmacwmfx_debug.dylib /private/var/ammonia/core/tweaks/libmacwmfx.dylib
	@sudo cp libmacwmfx.dylib.blacklist /private/var/ammonia/core/tweaks/
	$(call color_echo,$(GREEN)$(BOLD),✓ Installed debug dylib to /private/var/ammonia/core/tweaks/libmacwmfx.dylib)
	@echo ""
	$(call color_echo,$(YELLOW),Installing debug server dylib to /private/var/ammonia/core/tweaks/...)
	@sudo cp $(BUILD_DIR)/libmacwmfx_server_debug.dylib /private/var/ammonia/core/tweaks/libmacwmfx_server.dylib
	@sudo cp libmacwmfx_server.dylib.blacklist /private/var/ammonia/core/tweaks/
	$(call color_echo,$(GREEN)$(BOLD),✓ Installed debug server dylib to /private/var/ammonia/core/tweaks/libmacwmfx_server.dylib)
	@echo ""
	$(call color_echo,$(YELLOW),Installing CLI tool to /usr/local/bin/...)
	@sudo cp $(CLI_TARGET) /usr/local/bin/macwmfx
	@sudo chmod +x /usr/local/bin/macwmfx
	$(call color_echo,$(GREEN)$(BOLD),✓ Installed CLI tool to /usr/local/bin/macwmfx)
	@echo ""
	$(call color_echo,$(BLUE)$(BOLD),Opening test applications...)
	@for app in $(TEST_APPS); do \
		echo -e "$(CYAN)Opening $$app...$(RESET)"; \
		open -a "$$app" 2>/dev/null || echo -e "$(YELLOW)Could not open $$app (may not be installed)$(RESET)"; \
		sleep 1; \
	done
	@echo ""
	$(call color_echo,$(GREEN)$(BOLD),✓ Test installation complete! Debug version is now active.)
	$(call color_echo,$(CYAN),Test apps opened: $(TEST_APPS))
	$(call color_echo,$(CYAN),You can now use:)
	$(call color_echo,$(CYAN),  macwmfx --generate-config)
	$(call color_echo,$(CYAN),  macwmfx --reload)
	$(call color_echo,$(CYAN),  macwmfx --observe-logs)
	@echo ""
	$(call color_echo,$(YELLOW),Note: Debug logging is enabled. Check Console.app for macwmfx logs.)

# Clean build artifacts
clean:
	$(call color_echo,$(BLUE),Cleaning build artifacts...)
	rm -rf $(BUILD_DIR)
	$(call color_echo,$(GREEN)$(BOLD),✓ Cleaned build directory)

# Install target - always installs with debug enabled
install: all
	$(call color_echo,$(BLUE)$(BOLD),Installing macwmfx (with debug enabled)...)
	$(call color_echo,$(YELLOW),Creating directories...)
	@sudo mkdir -p /usr/local/lib /usr/local/bin /private/var/ammonia/core/tweaks
	$(call color_echo,$(YELLOW),Installing main dylib to /private/var/ammonia/core/tweaks/...)
	@sudo cp $(TARGET) /private/var/ammonia/core/tweaks/libmacwmfx.dylib
	@sudo cp libmacwmfx.dylib.blacklist /private/var/ammonia/core/tweaks/
	$(call color_echo,$(GREEN)$(BOLD),✓ Installed main dylib to /private/var/ammonia/core/tweaks/libmacwmfx.dylib)
	@echo ""
	$(call color_echo,$(YELLOW),Installing server dylib to /private/var/ammonia/core/tweaks/...)
	@sudo cp $(SERVER_TARGET) /private/var/ammonia/core/tweaks/libmacwmfx_server.dylib
	@sudo cp libmacwmfx_server.dylib.blacklist /private/var/ammonia/core/tweaks/
	$(call color_echo,$(GREEN)$(BOLD),✓ Installed server dylib to /private/var/ammonia/core/tweaks/libmacwmfx_server.dylib)
	@echo ""
	$(call color_echo,$(YELLOW),Installing CLI tool to /usr/local/bin/...)
	@sudo cp $(CLI_TARGET) /usr/local/bin/macwmfx
	@sudo chmod +x /usr/local/bin/macwmfx
	$(call color_echo,$(GREEN)$(BOLD),✓ Installed CLI tool to /usr/local/bin/macwmfx)
	@echo ""
	$(call color_echo,$(GREEN)$(BOLD),Installation complete! Debug mode is enabled.)
	$(call color_echo,$(CYAN),You can now use:)
	$(call color_echo,$(CYAN),  macwmfx --generate-config)
	$(call color_echo,$(CYAN),  macwmfx --reload)
	$(call color_echo,$(CYAN),  macwmfx --observe-logs)
	@echo ""
	$(call color_echo,$(YELLOW),Note: Debug logging is enabled. Check Console.app for macwmfx logs.)

# Uninstall target
uninstall:
	$(call color_echo,$(BLUE)$(BOLD),Uninstalling macwmfx...)
	$(call color_echo,$(YELLOW),Removing CLI tool...)
	@sudo rm -f /usr/local/bin/macwmfx
	$(call color_echo,$(GREEN)$(BOLD),✓ Removed CLI tool)
	@echo ""
	$(call color_echo,$(YELLOW),Removing macwmfx dylibs and blacklist files from /private/var/ammonia/core/tweaks/...)
	@sudo rm -f /private/var/ammonia/core/tweaks/libmacwmfx.dylib
	@sudo rm -f /private/var/ammonia/core/tweaks/libmacwmfx_server.dylib
	@sudo rm -f /private/var/ammonia/core/tweaks/libmacwmfx.dylib.blacklist
	@sudo rm -f /private/var/ammonia/core/tweaks/libmacwmfx_server.dylib.blacklist
	$(call color_echo,$(GREEN)$(BOLD),✓ Removed macwmfx dylibs and blacklist files)
	@echo ""
	$(call color_echo,$(YELLOW),Removing system configuration...)
	@sudo rm -f "/Library/Application Support/macwmfx/config.json"
	@sudo rm -rf "/Library/Application Support/macwmfx"
	$(call color_echo,$(GREEN)$(BOLD),✓ Removed system configuration)
	@echo ""
	$(call color_echo,$(GREEN)$(BOLD),Uninstallation complete! All macwmfx components have been removed.)
	$(call color_echo,$(CYAN),Note: Your user configuration at ~/.config/macwmfx/ has been preserved.)
	$(call color_echo,$(CYAN),Note: The /private/var/ammonia/core/tweaks/ directory has been preserved for other tweaks.)
	$(call color_echo,$(CYAN),Note: You may need to restart applications or reboot for changes to take full effect.)

# Help target
help:
	$(call color_echo,$(CYAN)$(BOLD),macwmfx Build System - Modular Architecture)
	$(call color_echo,$(CYAN),===========================================)
	@echo ""
	$(call color_echo,$(YELLOW)$(BOLD),Build Configurations:)
	$(call color_echo,$(CYAN),  make debug        - Debug build with verbose logging)
	$(call color_echo,$(CYAN),  make release      - Optimized release build)
	$(call color_echo,$(CYAN),  make minimal      - Minimal build (same as release))
	@echo ""
	$(call color_echo,$(YELLOW)$(BOLD),Important Note:)
	$(call color_echo,$(CYAN),  Debug mode is ALWAYS enabled regardless of build configuration)
	$(call color_echo,$(CYAN),  This ensures proper logging for troubleshooting)
	@echo ""
	$(call color_echo,$(YELLOW)$(BOLD),Other Targets:)
	$(call color_echo,$(CYAN),  make test         - Build debug version, install it, and open test apps)
	$(call color_echo,$(CYAN),  make clean        - Clean build artifacts)
	$(call color_echo,$(CYAN),  make install      - Install current version system-wide (dylib + server + CLI))
	$(call color_echo,$(CYAN),  make uninstall    - Remove all macwmfx components from system)
	$(call color_echo,$(CYAN),  make cli          - Build CLI tool only)
	$(call color_echo,$(CYAN),  make server       - Build server dylib only)
	$(call color_echo,$(CYAN),  make help         - Show this help)
	@echo ""
	$(call color_echo,$(YELLOW)$(BOLD),Test Apps:)
	$(call color_echo,$(CYAN),  $(TEST_APPS))
	@echo ""
	$(call color_echo,$(YELLOW)$(BOLD),Configuration Setup:)
	$(call color_echo,$(CYAN),  ./build/macwmfx --generate-config     # Create default config)
	@echo ""
	$(call color_echo,$(YELLOW)$(BOLD),After Installation:)
	$(call color_echo,$(CYAN),  macwmfx --generate-config             # Create default config)
	$(call color_echo,$(CYAN),  macwmfx --reload                      # Restart all apps)
	@echo ""
	$(call color_echo,$(YELLOW)$(BOLD),Project Structure:)
	$(call color_echo,$(CYAN),  src/core/         - Core functionality and managers)
	$(call color_echo,$(CYAN),  src/modules/      - Feature modules (windows, dock, etc.))
	$(call color_echo,$(CYAN),  src/server/       - Background server for app management)
	$(call color_echo,$(CYAN),  src/client/       - Client communication library)
	$(call color_echo,$(CYAN),  src/shared/       - Shared headers and libraries)
	$(call color_echo,$(CYAN),  build/            - Build output directory)
	@echo ""
	@echo ""
	$(call color_echo,$(YELLOW)$(BOLD)$(BOLD),    ╔══════════════════════════════════════════════════════════════╗)
	$(call color_echo,$(YELLOW)$(BOLD)$(BOLD),    ║                        SUPPORT MY WORK                       ║)
	$(call color_echo,$(YELLOW)$(BOLD)$(BOLD),    ╚══════════════════════════════════════════════════════════════╝)
	@echo ""
	$(call color_echo,$(CYAN)$(BOLD),  make fund         - Support the project (opens funding link))

# Fund target
fund:
	$(call color_echo,$(BLUE)$(BOLD),Opening funding link...)
	@open "https://ko-fi.com/aspauldingcode" || \
	$(call color_echo,$(RED),Could not open funding link. Please visit: https://ko-fi.com/aspauldingcode)
	$(call color_echo,$(GREEN)$(BOLD),✓ Funding link opened in browser)

# CLI tool build target
$(CLI_TARGET): $(CLI_OBJECT) $(BUILD_DIR)/config/configParser.m.o $(BUILD_DIR)/config/defineGlobals.m.o $(BUILD_DIR)/client/macwmfx_client.m.o $(BUILD_DIR)/server/macwmfx_server.m.o $(BUILD_DIR)/main/macwmfx.m.o $(BUILD_DIR)/main/module_loader.m.o $(BUILD_DIR)/modules/menubar/features/ribbonbar/HookUtil.m.o $(BUILD_DIR)/modules/windows/features/borders/WindowBorderModule.m.o $(BUILD_DIR)/shared/macwmfx_logging.m.o | $(BUILD_DIR)
	$(call color_echo,$(BLUE)$(BOLD),Linking macwmfx CLI tool...)
	$(CC) -o $@ $(CLI_OBJECT) $(BUILD_DIR)/config/configParser.m.o $(BUILD_DIR)/config/defineGlobals.m.o $(BUILD_DIR)/client/macwmfx_client.m.o $(BUILD_DIR)/server/macwmfx_server.m.o $(BUILD_DIR)/main/macwmfx.m.o $(BUILD_DIR)/main/module_loader.m.o $(BUILD_DIR)/modules/menubar/features/ribbonbar/HookUtil.m.o $(BUILD_DIR)/modules/windows/features/borders/WindowBorderModule.m.o $(BUILD_DIR)/shared/macwmfx_logging.m.o -framework Foundation -framework AppKit -framework CoreGraphics -isysroot $(SDKROOT) $(ARCHS)
	$(call color_echo,$(GREEN)$(BOLD),✓ CLI tool complete: $@)
	@echo ""
	$(call color_echo,$(CYAN),Usage:)
	$(call color_echo,$(CYAN),  $@ --generate-config     # Create default configuration)
	$(call color_echo,$(CYAN),  $@ --reload              # Restart all open apps)
	$(call color_echo,$(CYAN),  $@ --observe-logs        # Observe macwmfx logs)
