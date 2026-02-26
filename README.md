<div align="center">
<h1>🎛 Switchboard</h1>

<p>Auto-switch audio and video devices when you dock your Mac</p>
</div>

---

Switchboard is a menu bar daemon that monitors your lid state, display configuration, and connected peripherals — then picks the right mic, camera, and audio output so you don't have to.

## Prerequisites

- macOS 14+ (Sonoma)
- Xcode Command Line Tools

## Install

### Homebrew

```sh
brew tap maferland/tap && brew install --cask switchboard
```

### Build from source

```sh
git clone https://github.com/maferland/switchboard.git
cd switchboard
make install
```

## Usage

Switchboard runs as a menu bar icon. Click it to see current mode (Laptop / Clamshell), active devices, and preferences.

On first launch, it detects connected devices and suggests rules. Customize anytime via Preferences.

### Device Rules

| Condition | Camera | Mic | Output |
|-----------|--------|-----|--------|
| Clamshell + StreamCam | StreamCam | StreamCam mic | Headphones > external |
| Clamshell, no StreamCam | External cam | Built-in mic | Headphones > external |
| Laptop open | Built-in | Built-in | Headphones > external |
| **Always blocked** | — | Headphone/AirPods mic | Laptop speakers* |

\* Unless overridden in preferences.

### Config

Stored at `~/.config/switchboard/config.json`. Editable by hand or via Preferences.

## Privacy

No analytics, no tracking, no network requests. All data stays on device.

## Requirements

- macOS 14+ (Sonoma)
- Microphone permission (monitors devices, doesn't record)
- Camera permission (virtual camera proxy)
- System Extension approval (for virtual camera)

## Support

<a href="https://www.buymeacoffee.com/maferland" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" height="48"></a>

## License

[MIT](LICENSE)
