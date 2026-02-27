import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let configManager = ConfigManager()
    let audioManager = AudioDeviceManager()
    let cameraManager = CameraManager()
    let clamshellDetector = ClamshellDetector()
    private var eventMonitor: EventMonitor?

    lazy var windowState: WindowState = {
        WindowState(
            configManager: configManager,
            audioManager: audioManager,
            cameraManager: cameraManager
        )
    }()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let deviceController = DeviceController(audioManager: audioManager)

        let monitor = EventMonitor(
            audioManager: audioManager,
            cameraManager: cameraManager,
            clamshellDetector: clamshellDetector,
            configManager: configManager,
            deviceController: deviceController
        )
        monitor.onSelectionChanged = { [weak self] selection, clamshellState in
            self?.windowState.selection = selection
            self?.windowState.clamshellState = clamshellState
        }
        eventMonitor = monitor

        windowState.onSetOverride = { [weak monitor] category, name in
            monitor?.setOverride(category: category, deviceName: name)
        }

        print("[Switchboard] Started")
    }
}
