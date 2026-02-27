import SwiftUI
import ServiceManagement
import UniformTypeIdentifiers

struct SettingsView: View {
    let state: WindowState
    let onBack: () -> Void

    @State private var config: SwitchboardConfig
    @State private var selectedTab = 0

    init(state: WindowState, onBack: @escaping () -> Void) {
        self.state = state
        self.onBack = onBack
        self._config = State(initialValue: state.configManager.config)
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar
            Divider()

            VStack(alignment: .leading, spacing: 16) {
                SettingsRow {
                    Text("Start at Login")
                    Spacer()
                    Toggle("", isOn: loginBinding)
                        .toggleStyle(.switch)
                        .controlSize(.mini)
                        .labelsHidden()
                }

                modeToggle
                modeContent
            }
            .padding(16)
        }
        .onChange(of: config) { _, newValue in
            state.configManager.update { $0 = newValue }
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Button {
                onBack()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Spacer()

            Text("Settings")
                .font(.system(size: 14, weight: .semibold))

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: "chevron.left")
                Text("Back")
            }
            .hidden()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - Mode Toggle

    private var modeToggle: some View {
        HStack(spacing: 0) {
            modeTab("Laptop", icon: "laptopcomputer", isSelected: selectedTab == 0) {
                withAnimation(.easeInOut(duration: 0.2)) { selectedTab = 0 }
            }
            modeTab("Clamshell", icon: "rectangle.on.rectangle.angled", isSelected: selectedTab == 1) {
                withAnimation(.easeInOut(duration: 0.2)) { selectedTab = 1 }
            }
        }
    }

    private func modeTab(_ title: String, icon: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                Text(title)
                    .font(.system(size: 13, weight: isSelected ? .medium : .regular))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.blue.opacity(0.12) : Color.clear)
            )
            .foregroundStyle(isSelected ? .primary : .secondary)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Mode Content

    @ViewBuilder
    private var modeContent: some View {
        if selectedTab == 0 {
            modeSection(
                mic: $config.laptopMic,
                output: $config.laptopOutput,
                camera: $config.laptopCamera
            )
        } else {
            modeSection(
                mic: $config.clamshellMic,
                output: $config.clamshellOutput,
                camera: $config.clamshellCamera
            )
        }
    }

    private func modeSection(
        mic: Binding<[String]>,
        output: Binding<[String]>,
        camera: Binding<[String]>
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            PriorityList(
                label: "Microphones",
                icon: "mic.fill",
                priorities: mic,
                available: state.audioManager.inputDevices().map(\.name)
            )
            PriorityList(
                label: "Speakers",
                icon: "speaker.wave.2.fill",
                priorities: output,
                available: state.audioManager.outputDevices().map(\.name)
            )
            PriorityList(
                label: "Cameras",
                icon: "web.camera",
                priorities: camera,
                available: state.cameraManager.allCameras().map(\.name)
            )
        }
    }

    // MARK: - Login Binding

    private var loginBinding: Binding<Bool> {
        Binding(
            get: { SMAppService.mainApp.status == .enabled },
            set: { enabled in
                do {
                    if enabled {
                        try SMAppService.mainApp.register()
                    } else {
                        try SMAppService.mainApp.unregister()
                    }
                } catch {
                    print("[Switchboard] Login item error: \(error)")
                }
            }
        )
    }
}

// MARK: - Priority List

private struct PriorityList: View {
    let label: String
    let icon: String
    @Binding var priorities: [String]
    let available: [String]

    @State private var draggingName: String?

    private var merged: [String] {
        var result = priorities.filter { available.contains($0) }
        for name in available where !result.contains(name) {
            result.append(name)
        }
        return result
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .padding(.leading, 4)

            ForEach(Array(merged.enumerated()), id: \.element) { index, name in
                deviceRow(index: index, name: name)
            }
        }
        .onAppear { syncPriorities() }
        .onChange(of: available) { _, _ in syncPriorities() }
    }

    private func syncPriorities() {
        let current = merged
        if priorities != current {
            priorities = current
        }
    }

    private func deviceRow(index: Int, name: String) -> some View {
        let isFirst = index == 0
        return HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(isFirst ? Color.blue : Color.secondary)
                .frame(width: 16)
            Text(name)
                .lineLimit(1)
                .font(.system(size: 13))
            Spacer()
            if isFirst {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(.blue)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isFirst ? Color.blue.opacity(0.1) : Color.primary.opacity(0.06))
        )
        .opacity(draggingName == name ? 0.4 : 1)
        .draggable(name) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(name)
                    .font(.system(size: 13))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
        }
        .dropDestination(for: String.self) { items, _ in
            guard let dropped = items.first, dropped != name else { return false }
            var list = merged
            guard let from = list.firstIndex(of: dropped),
                  let to = list.firstIndex(of: name) else { return false }
            withAnimation(.easeInOut(duration: 0.2)) {
                list.move(fromOffsets: IndexSet(integer: from), toOffset: to > from ? to + 1 : to)
                priorities = list
            }
            return true
        } isTargeted: { targeted in
            if targeted {
                draggingName = nil
            }
        }
        .onDrag {
            draggingName = name
            return NSItemProvider(object: name as NSString)
        }
    }
}
