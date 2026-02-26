import CoreAudio

enum AudioDeviceTransport: String, Codable {
    case builtIn
    case usb
    case bluetooth
    case bluetoothLE
    case hdmi
    case aggregate
    case virtual
    case unknown

    init(transportType: UInt32) {
        switch transportType {
        case kAudioDeviceTransportTypeBuiltIn: self = .builtIn
        case kAudioDeviceTransportTypeUSB: self = .usb
        case kAudioDeviceTransportTypeBluetooth: self = .bluetooth
        case kAudioDeviceTransportTypeBluetoothLE: self = .bluetoothLE
        case kAudioDeviceTransportTypeHDMI: self = .hdmi
        case kAudioDeviceTransportTypeAggregate: self = .aggregate
        case kAudioDeviceTransportTypeVirtual: self = .virtual
        default: self = .unknown
        }
    }
}

struct AudioDevice: Equatable, Identifiable {
    let id: AudioObjectID
    let name: String
    let uid: String
    let transport: AudioDeviceTransport
    let hasInput: Bool
    let hasOutput: Bool

    var isBuiltIn: Bool { transport == .builtIn }
    var isBluetooth: Bool { transport == .bluetooth || transport == .bluetoothLE }
    var isUSB: Bool { transport == .usb }
    var isHDMI: Bool { transport == .hdmi }
}
