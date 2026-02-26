import CoreAudio

enum ClamshellState {
    case open
    case closed
}

enum DeviceCategory: String, Codable {
    case mic
    case output
    case camera
}

struct CurrentDefaults {
    let inputDeviceID: AudioObjectID?
    let outputDeviceID: AudioObjectID?
}

struct DeviceState {
    let clamshellState: ClamshellState
    let audioDevices: [AudioDevice]
    let videoDevices: [VideoDevice]
    let currentDefaults: CurrentDefaults
    let overrides: [DeviceCategory: String] // device name overrides
}
