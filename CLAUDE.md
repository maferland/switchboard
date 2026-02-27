# Switchboard

macOS menu bar app — auto-switches audio/video devices based on clamshell mode.

## Build & Run

```sh
make build        # release build
make app          # release build + package .app + DMG (runs tests first)
swift run Switchboard  # run directly (debug)
```

## Test

```sh
make test         # swift test
```

## Install

```sh
make install      # builds .app, copies to /Applications
```

## Architecture

- **Sources/Switchboard/** — SwiftUI App + MenuBarExtra, CoreAudio, IOKit
- **Sources/SwitchboardCamera/** — CMIOExtension virtual camera (needs Xcode for .appex)
- **Tests/SwitchboardTests/** — Unit tests (RuleEngine, ClamshellDetector, ConfigManager)

## Key Patterns

- Combine publishers for device/state changes
- Pure RuleEngine: `evaluate(state:) -> DeviceSelection`
- Priority-list config: `[String]` arrays per mode per category, first available wins
- Config at `~/.config/switchboard/config.json`
- SwiftUI App + MenuBarExtra(.window) for menu bar
- SMAppService for Start at Login
- After code changes, always reboot: `pkill -f '.build/debug/Switchboard'; sleep 0.5; swift run Switchboard &`
