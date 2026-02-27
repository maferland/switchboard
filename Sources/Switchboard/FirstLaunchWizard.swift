import SwiftUI

struct FirstLaunchView: View {
    let state: WindowState
    let onDone: () -> Void

    @State private var clamshellMic: String?
    @State private var clamshellOutput: String?
    @State private var clamshellCamera: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Welcome to Switchboard")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Detected devices — pick your clamshell setup")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }

                SettingsSection("CAMERAS") {
                    ForEach(state.cameraManager.allCameras()) { cam in
                        SettingsRow {
                            Image(systemName: cam.isBuiltIn ? "laptopcomputer" : "web.camera")
                                .frame(width: 20)
                                .foregroundStyle(.secondary)
                            Text(cam.name)
                            Spacer()
                            if cam.isBuiltIn {
                                Text("Built-in")
                                    .foregroundStyle(.tertiary)
                                    .font(.system(size: 12))
                            }
                        }
                    }
                }

                SettingsSection("MICROPHONES") {
                    ForEach(state.audioManager.inputDevices(), id: \.id) { mic in
                        SettingsRow {
                            Image(systemName: "mic")
                                .frame(width: 20)
                                .foregroundStyle(.secondary)
                            Text(mic.name)
                            Spacer()
                            Text(mic.transport.displayName)
                                .foregroundStyle(.tertiary)
                                .font(.system(size: 12))
                        }
                    }
                }

                SettingsSection("CLAMSHELL PREFERRED") {
                    SettingsRow {
                        Text("Microphone")
                        Spacer()
                        Picker("", selection: $clamshellMic) {
                            Text("Auto").tag(nil as String?)
                            ForEach(state.audioManager.inputDevices(), id: \.id) { mic in
                                Text(mic.name).tag(mic.name as String?)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                    }
                    SettingsRow {
                        Text("Output")
                        Spacer()
                        Picker("", selection: $clamshellOutput) {
                            Text("Auto").tag(nil as String?)
                            ForEach(state.audioManager.outputDevices(), id: \.id) { out in
                                Text(out.name).tag(out.name as String?)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                    }
                    SettingsRow {
                        Text("Camera")
                        Spacer()
                        Picker("", selection: $clamshellCamera) {
                            Text("Auto").tag(nil as String?)
                            ForEach(state.cameraManager.allCameras()) { cam in
                                Text(cam.name).tag(cam.name as String?)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                    }
                }

                Button("Save & Start") {
                    var config = SwitchboardConfig()
                    if let clamshellMic { config.clamshellMic = [clamshellMic] }
                    if let clamshellOutput { config.clamshellOutput = [clamshellOutput] }
                    if let clamshellCamera { config.clamshellCamera = [clamshellCamera] }
                    state.configManager.update { $0 = config }
                    onDone()
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(24)
        }
    }
}
