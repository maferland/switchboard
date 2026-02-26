import SwiftUI
import AppKit

final class FirstLaunchWindowController {
    private var window: NSWindow?

    func showIfNeeded(configManager: ConfigManager, audioManager: AudioDeviceManager, cameraManager: CameraManager) {
        guard configManager.isFirstLaunch else { return }

        let view = FirstLaunchWizard(
            configManager: configManager,
            audioManager: audioManager,
            cameraManager: cameraManager
        ) { [weak self] in
            self?.window?.close()
        }

        let hostingController = NSHostingController(rootView: view)
        let win = NSWindow(contentViewController: hostingController)
        win.title = "Welcome to Switchboard"
        win.styleMask = [.titled]
        win.setContentSize(NSSize(width: 480, height: 520))
        win.center()
        win.makeKeyAndOrderFront(nil)
        window = win

        NSApp.activate(ignoringOtherApps: true)
    }
}

struct FirstLaunchWizard: View {
    let configManager: ConfigManager
    let audioManager: AudioDeviceManager
    let cameraManager: CameraManager
    let onDone: () -> Void

    @State private var config: SwitchboardConfig

    init(configManager: ConfigManager, audioManager: AudioDeviceManager, cameraManager: CameraManager, onDone: @escaping () -> Void) {
        self.configManager = configManager
        self.audioManager = audioManager
        self.cameraManager = cameraManager
        self.onDone = onDone

        // Auto-detect defaults
        var detected = SwitchboardConfig()
        let cameras = cameraManager.allCameras()
        let inputs = audioManager.inputDevices()

        // Detect StreamCam
        if let streamCam = cameras.first(where: { $0.name.localizedCaseInsensitiveContains("StreamCam") }) {
            detected.clamshellCamera = streamCam.name
            if let streamMic = inputs.first(where: { $0.name.localizedCaseInsensitiveContains("StreamCam") }) {
                detected.clamshellMic = streamMic.name
            }
        }

        self._config = State(initialValue: detected)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Switchboard Setup")
                .font(.title)

            Text("Here's what I detected — does this look right?")
                .foregroundStyle(.secondary)

            GroupBox("Cameras") {
                ForEach(cameraManager.allCameras()) { cam in
                    HStack {
                        Image(systemName: cam.isBuiltIn ? "laptopcomputer" : "web.camera")
                        Text(cam.name)
                        Spacer()
                        if cam.isBuiltIn { Text("Built-in").foregroundStyle(.secondary) }
                    }
                    .padding(.vertical, 2)
                }
            }

            GroupBox("Microphones") {
                ForEach(audioManager.inputDevices(), id: \.id) { mic in
                    HStack {
                        Image(systemName: "mic")
                        Text(mic.name)
                        Spacer()
                        Text(mic.transport.rawValue).foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                }
            }

            GroupBox("Clamshell Rules") {
                Picker("Camera in clamshell", selection: $config.clamshellCamera) {
                    Text("Auto").tag(nil as String?)
                    ForEach(cameraManager.allCameras()) { cam in
                        Text(cam.name).tag(cam.name as String?)
                    }
                }
                Picker("Mic in clamshell", selection: $config.clamshellMic) {
                    Text("Auto").tag(nil as String?)
                    ForEach(audioManager.inputDevices(), id: \.id) { mic in
                        Text(mic.name).tag(mic.name as String?)
                    }
                }
            }

            Spacer()

            HStack {
                Spacer()
                Button("Save & Start") {
                    configManager.update { $0 = config }
                    onDone()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
    }
}
