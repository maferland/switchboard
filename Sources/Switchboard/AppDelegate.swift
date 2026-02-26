import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarController: MenuBarController?
    private var audioManager: AudioDeviceManager?
    private var cameraManager: CameraManager?
    private var clamshellDetector: ClamshellDetector?
    private var configManager: ConfigManager?
    private var eventMonitor: EventMonitor?
    private let preferencesController = PreferencesWindowController()
    private let firstLaunchController = FirstLaunchWindowController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        let configMgr = ConfigManager()
        configManager = configMgr

        let audioMgr = AudioDeviceManager()
        audioManager = audioMgr

        let cameraMgr = CameraManager()
        cameraManager = cameraMgr

        let clamshell = ClamshellDetector()
        clamshellDetector = clamshell

        let menuBar = MenuBarController()
        menuBar.onOpenPreferences = { [weak self] in
            guard let self, let cm = self.configManager, let am = self.audioManager, let cam = self.cameraManager else { return }
            self.preferencesController.show(configManager: cm, audioManager: am, cameraManager: cam)
        }
        menuBarController = menuBar

        let ruleEngine = RuleEngine(config: configMgr.config)
        let deviceController = DeviceController(audioManager: audioMgr)

        eventMonitor = EventMonitor(
            audioManager: audioMgr,
            cameraManager: cameraMgr,
            clamshellDetector: clamshell,
            ruleEngine: ruleEngine,
            deviceController: deviceController,
            menuBarController: menuBar
        )

        // Show first launch wizard if needed
        firstLaunchController.showIfNeeded(
            configManager: configMgr,
            audioManager: audioMgr,
            cameraManager: cameraMgr
        )

        print("[Switchboard] Started")
    }
}
