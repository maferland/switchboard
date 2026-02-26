import AppKit

final class MenuBarController {
    private let statusItem: NSStatusItem
    var onOpenPreferences: (() -> Void)?

    init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = "🎛"
        buildMenu()
    }

    func update(selection: DeviceSelection) {
        let menu = NSMenu()

        let modeItem = NSMenuItem(title: selection.reason, action: nil, keyEquivalent: "")
        modeItem.isEnabled = false
        menu.addItem(modeItem)
        menu.addItem(.separator())

        if let mic = selection.preferredMic {
            let micItem = NSMenuItem(title: "🎤 \(mic.name)", action: nil, keyEquivalent: "")
            micItem.isEnabled = false
            menu.addItem(micItem)
        }

        if let output = selection.preferredOutput {
            let outItem = NSMenuItem(title: "🔊 \(output.name)", action: nil, keyEquivalent: "")
            outItem.isEnabled = false
            menu.addItem(outItem)
        }

        if let cam = selection.preferredCamera {
            let camItem = NSMenuItem(title: "📷 \(cam.name)", action: nil, keyEquivalent: "")
            camItem.isEnabled = false
            menu.addItem(camItem)
        }

        menu.addItem(.separator())

        let prefsItem = NSMenuItem(title: "Preferences…", action: #selector(prefsClicked), keyEquivalent: ",")
        prefsItem.target = self
        menu.addItem(prefsItem)

        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit Switchboard", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        statusItem.menu = menu
    }

    // MARK: - Private

    private func buildMenu() {
        let menu = NSMenu()

        let placeholder = NSMenuItem(title: "Detecting devices…", action: nil, keyEquivalent: "")
        placeholder.isEnabled = false
        menu.addItem(placeholder)

        menu.addItem(.separator())

        let prefsItem = NSMenuItem(title: "Preferences…", action: #selector(prefsClicked), keyEquivalent: ",")
        prefsItem.target = self
        menu.addItem(prefsItem)

        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit Switchboard", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        statusItem.menu = menu
    }

    @objc private func prefsClicked() {
        onOpenPreferences?()
    }
}
