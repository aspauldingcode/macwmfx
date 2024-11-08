# Makefile to build the StopStoplightLight plugin using xcodebuild

# Directories
PROJECT_DIR = StopStoplightLight
BUILD_DIR = build
INSTALL_DIR = /Library/Application\ Support/MacEnhance/Plugins/

# Target
TARGET = StopStoplightLight

# Rules
all: build

build:
	xcodebuild -project $(PROJECT_DIR).xcodeproj -scheme $(TARGET) -configuration Release build CONFIGURATION_BUILD_DIR=$(BUILD_DIR)

clean:
	xcodebuild -project $(PROJECT_DIR).xcodeproj -scheme $(TARGET) -configuration Release clean
	rm -rf $(BUILD_DIR)

test: build
	killall "MacForgeHelper" || true
	killall MacForge || true
	sudo rm -rf $(INSTALL_DIR)/$(TARGET).bundle
	sudo cp -r $(BUILD_DIR)/$(TARGET).bundle $(INSTALL_DIR)
	killall "System Settings" || true
	killall "Spotify" || true
	killall "Chess" || true
	open -a "MacForge" --hide
	sleep 2
	open -a "System Settings"
	open -a "Spotify"
	open -a "Chess"

.PHONY: all build clean test