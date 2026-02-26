import Foundation

struct RuleEngine {
    let config: SwitchboardConfig

    func evaluate(state: DeviceState) -> DeviceSelection {
        let mic = selectMic(state: state)
        let output = selectOutput(state: state)
        let camera = selectCamera(state: state)
        let reason = describeMode(state: state)

        return DeviceSelection(
            preferredMic: mic,
            preferredOutput: output,
            preferredCamera: camera,
            reason: reason
        )
    }

    // MARK: - Mic Selection

    private func selectMic(state: DeviceState) -> AudioDevice? {
        // 1. Manual override
        if let overrideName = state.overrides[.mic],
           let device = state.audioDevices.first(where: { $0.name == overrideName && $0.hasInput }) {
            return device
        }

        let inputs = state.audioDevices.filter(\.hasInput)
        let allowed = inputs.filter { !isMicBlocked($0) }

        // 2. Clamshell + StreamCam → StreamCam mic
        if state.clamshellState == .closed,
           let streamCam = allowed.first(where: { isStreamCam($0) }) {
            return streamCam
        }

        // 3. Clamshell, no StreamCam → built-in mic
        if state.clamshellState == .closed {
            return allowed.first(where: \.isBuiltIn)
        }

        // 4. Laptop open → built-in mic
        return allowed.first(where: \.isBuiltIn)
    }

    // MARK: - Output Selection

    private func selectOutput(state: DeviceState) -> AudioDevice? {
        // 1. Manual override
        if let overrideName = state.overrides[.output],
           let device = state.audioDevices.first(where: { $0.name == overrideName && $0.hasOutput }) {
            return device
        }

        let outputs = state.audioDevices.filter(\.hasOutput)

        // Priority: headphones (BT/wired/USB) > external speaker > nothing
        // Block laptop speakers unless allowed
        let headphones = outputs.first(where: { $0.isBluetooth || ($0.isUSB && !isStreamCam($0)) })
        if let headphones { return headphones }

        let external = outputs.first(where: { $0.isHDMI || ($0.isUSB && !$0.hasInput) })
        if let external { return external }

        // Laptop speakers — only if explicitly allowed
        if config.allowLaptopSpeakers {
            return outputs.first(where: \.isBuiltIn)
        }

        // Last resort: allow built-in if it's the only option
        if outputs.allSatisfy(\.isBuiltIn) {
            return outputs.first(where: { $0.hasOutput && $0.isBuiltIn })
        }

        return outputs.first(where: { !isOutputBlocked($0) })
    }

    // MARK: - Camera Selection

    private func selectCamera(state: DeviceState) -> VideoDevice? {
        // 1. Manual override
        if let overrideName = state.overrides[.camera],
           let device = state.videoDevices.first(where: { $0.name == overrideName }) {
            return device
        }

        // 2. Clamshell + StreamCam → StreamCam
        if state.clamshellState == .closed,
           let streamCam = state.videoDevices.first(where: {
               $0.name.localizedCaseInsensitiveContains(config.streamCamKeyword)
           }) {
            return streamCam
        }

        // 3. Clamshell, no StreamCam → first external
        if state.clamshellState == .closed,
           let external = state.videoDevices.first(where: { !$0.isBuiltIn }) {
            return external
        }

        // 4. Laptop open → built-in
        return state.videoDevices.first(where: \.isBuiltIn)
    }

    // MARK: - Filters

    private func isMicBlocked(_ device: AudioDevice) -> Bool {
        config.blockedMicKeywords.contains { keyword in
            device.name.localizedCaseInsensitiveContains(keyword)
        }
    }

    private func isOutputBlocked(_ device: AudioDevice) -> Bool {
        config.blockedOutputKeywords.contains { keyword in
            device.name.localizedCaseInsensitiveContains(keyword)
        }
    }

    private func isStreamCam(_ device: AudioDevice) -> Bool {
        device.name.localizedCaseInsensitiveContains(config.streamCamKeyword)
    }

    // MARK: - Mode Description

    private func describeMode(state: DeviceState) -> String {
        switch state.clamshellState {
        case .closed: "Clamshell Mode"
        case .open: "Laptop Mode"
        }
    }
}
