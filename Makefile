VERSION := $(shell git describe --tags 2>/dev/null || echo "v0.0.0")
BINARY := Switchboard
BUILD_DIR := .build/release
INSTALL_DIR := /usr/local/bin
LAUNCH_AGENT_DIR := $(HOME)/Library/LaunchAgents
PLIST := com.maferland.switchboard.plist

.PHONY: build test app install clean release

build:
	swift build

test:
	swift test

app: test
	swift build -c release

install: app
	cp $(BUILD_DIR)/$(BINARY) $(INSTALL_DIR)/switchboard
	cp LaunchAgent/$(PLIST) $(LAUNCH_AGENT_DIR)/$(PLIST)
	launchctl load $(LAUNCH_AGENT_DIR)/$(PLIST)

clean:
	swift package clean
	rm -rf .build

release: test
	swift build -c release
	@echo "Built $(BINARY) $(VERSION)"
