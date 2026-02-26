import CoreAudio
import Foundation

final class DeviceController {
    private let audioManager: AudioDeviceManager

    init(audioManager: AudioDeviceManager) {
        self.audioManager = audioManager
    }

    func apply(selection: DeviceSelection) {
        if let mic = selection.preferredMic {
            applyInput(mic)
        }
        if let output = selection.preferredOutput {
            applyOutput(output)
        }
        // Camera is informational only (virtual cam handles routing)
    }

    private func applyInput(_ device: AudioDevice) {
        guard let currentID = audioManager.defaultInputDeviceID(),
              currentID != device.id else { return }
        let ok = audioManager.setDefaultInput(device.id)
        if ok {
            print("[Switchboard] Input → \(device.name)")
        }
    }

    private func applyOutput(_ device: AudioDevice) {
        guard let currentID = audioManager.defaultOutputDeviceID(),
              currentID != device.id else { return }
        let ok = audioManager.setDefaultOutput(device.id)
        if ok {
            print("[Switchboard] Output → \(device.name)")
        }
    }
}
