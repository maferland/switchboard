import SwiftUI
import AppKit

@MainActor
final class WindowState: ObservableObject {
    @Published var selection: DeviceSelection?
    @Published var clamshellState: ClamshellState = .open
    @Published var overrides: [DeviceCategory: String] = [:]

    let configManager: ConfigManager
    let audioManager: AudioDeviceManager
    let cameraManager: CameraManager

    var onSetOverride: ((DeviceCategory, String?) -> Void)?

    init(configManager: ConfigManager, audioManager: AudioDeviceManager, cameraManager: CameraManager) {
        self.configManager = configManager
        self.audioManager = audioManager
        self.cameraManager = cameraManager
    }

    func setOverride(category: DeviceCategory, deviceName: String?) {
        if let deviceName {
            overrides[category] = deviceName
        } else {
            overrides.removeValue(forKey: category)
        }
        onSetOverride?(category, deviceName)
    }

    func toggleDevice(category: DeviceCategory, deviceName: String) {
        if overrides[category] == deviceName {
            setOverride(category: category, deviceName: nil)
        } else {
            setOverride(category: category, deviceName: deviceName)
        }
    }
}

struct MainView: View {
    @ObservedObject var state: WindowState
    @State private var showSettings = false
    @State private var showFirstLaunch: Bool

    init(state: WindowState) {
        self.state = state
        self._showFirstLaunch = State(initialValue: state.configManager.isFirstLaunch)
    }

    var body: some View {
        Group {
            if showFirstLaunch {
                FirstLaunchView(state: state) {
                    showFirstLaunch = false
                }
            } else if showSettings {
                SettingsView(state: state) {
                    showSettings = false
                }
            } else {
                peripheralListView
            }
        }
        .frame(width: 320)
    }

    // MARK: - Peripheral List

    private var peripheralListView: some View {
        VStack(spacing: 0) {
            topBar
            Divider()
            VStack(alignment: .leading, spacing: 16) {
                microphoneSection
                speakerSection
                cameraSection
            }
            .padding(16)
            Spacer(minLength: 0)
            Divider()
            bottomBar
        }
    }

    private var topBar: some View {
        HStack(spacing: 8) {
            ModeBadge(mode: state.clamshellState)
            Spacer()
            Text("v0.1.0")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
            Button {
                withAnimation(.easeInOut(duration: 0.25)) { showSettings = true }
            } label: {
                Image(systemName: "gear")
                    .font(.system(size: 14))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var microphoneSection: some View {
        let inputs = state.audioManager.inputDevices()
        let activeName = state.selection?.preferredMic?.name
        return SettingsSection("Microphones") {
            ForEach(inputs, id: \.id) { mic in
                DeviceRow(
                    icon: "mic.fill",
                    name: mic.name,
                    detail: mic.transport.displayName,
                    isActive: mic.name == activeName
                ) {
                    state.toggleDevice(category: .mic, deviceName: mic.name)
                }
            }
        }
    }

    private var speakerSection: some View {
        let outputs = state.audioManager.outputDevices()
        let activeName = state.selection?.preferredOutput?.name
        return SettingsSection("Speakers") {
            ForEach(outputs, id: \.id) { out in
                DeviceRow(
                    icon: "speaker.wave.2.fill",
                    name: out.name,
                    detail: out.transport.displayName,
                    isActive: out.name == activeName
                ) {
                    state.toggleDevice(category: .output, deviceName: out.name)
                }
            }
        }
    }

    private var cameraSection: some View {
        let cameras = state.cameraManager.allCameras()
        let activeName = state.selection?.preferredCamera?.name
        return SettingsSection("Cameras") {
            ForEach(cameras) { cam in
                DeviceRow(
                    icon: "web.camera",
                    name: cam.name,
                    detail: cam.isBuiltIn ? "Built-in" : "External",
                    isActive: cam.name == activeName
                ) {
                    state.toggleDevice(category: .camera, deviceName: cam.name)
                }
            }
        }
    }

    private var bottomBar: some View {
        HStack {
            Button {
                if let url = URL(string: "https://buymeacoffee.com/maferland") {
                    NSWorkspace.shared.open(url)
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "heart")
                    Text("Support")
                }
                .font(.system(size: 12))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)

            Spacer()

            Button("Quit  \u{2318}Q") {
                NSApp.terminate(nil)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .font(.system(size: 12))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}
