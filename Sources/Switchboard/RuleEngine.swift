import Foundation

struct RuleEngine {
    let config: SwitchboardConfig

    func evaluate(state: DeviceState) -> DeviceSelection {
        DeviceSelection(
            preferredMic: selectMic(state: state),
            preferredOutput: selectOutput(state: state),
            preferredCamera: selectCamera(state: state),
            reason: state.clamshellState == .closed ? "Clamshell Mode" : "Laptop Mode"
        )
    }

    // MARK: - Mic Selection

    private func selectMic(state: DeviceState) -> AudioDevice? {
        let inputs = state.audioDevices.filter(\.hasInput)

        // 1. Manual override
        if let name = state.overrides[.mic],
           let device = inputs.first(where: { $0.name == name }) {
            return device
        }

        // 2. Priority list from config
        let priorities = state.clamshellState == .closed ? config.clamshellMic : config.laptopMic
        for name in priorities {
            if let device = inputs.first(where: { $0.name == name }) {
                return device
            }
        }

        // 3. Fallback: built-in
        return inputs.first(where: \.isBuiltIn)
    }

    // MARK: - Output Selection

    private func selectOutput(state: DeviceState) -> AudioDevice? {
        let outputs = state.audioDevices.filter(\.hasOutput)

        // 1. Manual override
        if let name = state.overrides[.output],
           let device = outputs.first(where: { $0.name == name }) {
            return device
        }

        // 2. Priority list from config
        let priorities = state.clamshellState == .closed ? config.clamshellOutput : config.laptopOutput
        for name in priorities {
            if let device = outputs.first(where: { $0.name == name }) {
                return device
            }
        }

        // 3. Fallback: BT/USB > HDMI > built-in (only if no external)
        if let btOrUsb = outputs.first(where: { $0.isBluetooth || $0.isUSB }) {
            return btOrUsb
        }
        if let hdmi = outputs.first(where: \.isHDMI) {
            return hdmi
        }
        let hasExternal = outputs.contains { !$0.isBuiltIn }
        if !hasExternal {
            return outputs.first(where: \.isBuiltIn)
        }
        return outputs.first
    }

    // MARK: - Camera Selection

    private func selectCamera(state: DeviceState) -> VideoDevice? {
        let cameras = state.videoDevices

        // 1. Manual override
        if let name = state.overrides[.camera],
           let device = cameras.first(where: { $0.name == name }) {
            return device
        }

        // 2. Priority list from config
        let priorities = state.clamshellState == .closed ? config.clamshellCamera : config.laptopCamera
        for name in priorities {
            if let device = cameras.first(where: { $0.name == name }) {
                return device
            }
        }

        // 3. Fallback
        if state.clamshellState == .closed {
            return cameras.first(where: { !$0.isBuiltIn }) ?? cameras.first(where: \.isBuiltIn)
        }
        return cameras.first(where: \.isBuiltIn)
    }
}
