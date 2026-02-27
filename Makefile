.PHONY: build test release install clean app update-homebrew-tap

VERSION ?= $(shell git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0")
NEXT_VERSION ?= $(VERSION)

build:
	swift build -c release

test:
	swift test

app: test
	./scripts/package_app.sh $(NEXT_VERSION)

install: app
	cp -R Switchboard.app /Applications/
	@echo "Installed Switchboard.app to /Applications"

clean:
	rm -rf .build *.dmg Switchboard.app

update-homebrew-tap:
	./scripts/update_homebrew_tap.sh $(NEXT_VERSION) Switchboard-$(NEXT_VERSION)-macos.dmg

release: app
	@if [ "$(VERSION)" = "$(NEXT_VERSION)" ]; then \
		echo "Error: specify NEXT_VERSION=vX.Y.Z"; exit 1; \
	fi
	gh release create $(NEXT_VERSION) Switchboard-$(NEXT_VERSION)-macos.dmg \
		--title "Switchboard $(NEXT_VERSION)" \
		--generate-notes
	$(MAKE) update-homebrew-tap
	@rm Switchboard-$(NEXT_VERSION)-macos.dmg
