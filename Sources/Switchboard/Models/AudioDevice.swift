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

    var displayName: String {
        switch self {
        case .builtIn: "Built-in"
        case .usb: "USB"
        case .bluetooth, .bluetoothLE: "Bluetooth"
        case .hdmi: "HDMI"
        case .aggregate: "Aggregate"
        case .virtual: "Virtual"
        case .unknown: "Unknown"
        }
    }

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
