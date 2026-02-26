import SwiftUI
import AppKit

final class PreferencesWindowController {
    private var window: NSWindow?

    func show(configManager: ConfigManager, audioManager: AudioDeviceManager, cameraManager: CameraManager) {
        if let window, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            return
        }

        let view = PreferencesView(
            configManager: configManager,
            audioManager: audioManager,
            cameraManager: cameraManager
        )

        let hostingController = NSHostingController(rootView: view)
        let win = NSWindow(contentViewController: hostingController)
        win.title = "Switchboard Preferences"
        win.styleMask = [.titled, .closable]
        win.setContentSize(NSSize(width: 420, height: 480))
        win.center()
        win.makeKeyAndOrderFront(nil)
        window = win

        NSApp.activate(ignoringOtherApps: true)
    }
}

struct PreferencesView: View {
    let configManager: ConfigManager
    let audioManager: AudioDeviceManager
    let cameraManager: CameraManager

    @State private var config: SwitchboardConfig

    init(configManager: ConfigManager, audioManager: AudioDeviceManager, cameraManager: CameraManager) {
        self.configManager = configManager
        self.audioManager = audioManager
        self.cameraManager = cameraManager
        self._config = State(initialValue: configManager.config)
    }

    var body: some View {
        Form {
            Section("Clamshell Mode") {
                Picker("Camera", selection: $config.clamshellCamera) {
                    Text("Auto").tag(nil as String?)
                    ForEach(cameraManager.allCameras()) { cam in
                        Text(cam.name).tag(cam.name as String?)
                    }
                }

                Picker("Microphone", selection: $config.clamshellMic) {
                    Text("Auto").tag(nil as String?)
                    ForEach(audioManager.inputDevices(), id: \.id) { mic in
                        Text(mic.name).tag(mic.name as String?)
                    }
                }
            }

            Section("Blocked Devices") {
                TextField("Blocked mic keywords (comma-separated)", text: blockedMicBinding)
                TextField("Blocked output keywords (comma-separated)", text: blockedOutputBinding)
            }

            Section("StreamCam") {
                TextField("StreamCam keyword", text: $config.streamCamKeyword)
            }

            Section("Options") {
                Toggle("Allow laptop speakers as output", isOn: $config.allowLaptopSpeakers)
            }
        }
        .formStyle(.grouped)
        .padding()
        .onChange(of: config) { _, newValue in
            configManager.update { $0 = newValue }
        }
    }

    private var blockedMicBinding: Binding<String> {
        Binding(
            get: { config.blockedMicKeywords.joined(separator: ", ") },
            set: { config.blockedMicKeywords = $0.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) } }
        )
    }

    private var blockedOutputBinding: Binding<String> {
        Binding(
            get: { config.blockedOutputKeywords.joined(separator: ", ") },
            set: { config.blockedOutputKeywords = $0.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) } }
        )
    }
}
