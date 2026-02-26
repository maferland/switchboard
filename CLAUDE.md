# Switchboard

macOS menu bar daemon — auto-switches audio/video devices based on clamshell mode.

## Build & Run

```sh
make build        # debug build
make app          # release build (runs tests first)
swift run Switchboard  # run directly
```

## Test

```sh
make test         # swift test
```

## Install

```sh
make install      # copies binary + LaunchAgent, loads it
```

## Architecture

- **Sources/Switchboard/** — Main menu bar app (NSApplication, CoreAudio, IOKit)
- **Sources/SwitchboardCamera/** — CMIOExtension virtual camera (needs Xcode for .appex)
- **Tests/SwitchboardTests/** — Unit tests (RuleEngine, ClamshellDetector, ConfigManager)

## Key Patterns

- Combine publishers for device/state changes
- Pure RuleEngine: `evaluate(state:) -> DeviceSelection`
- Config at `~/.config/switchboard/config.json`
- No SwiftUI App lifecycle — NSApplication + NSStatusItem for menu bar
