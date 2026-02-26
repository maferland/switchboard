import Foundation
import CoreMediaIO

final class SwitchboardCameraDevice: NSObject, CMIOExtensionDeviceSource {
    private(set) var device: CMIOExtensionDevice!
    private let stream: SwitchboardCameraStream

    override init() {
        stream = SwitchboardCameraStream()
        super.init()

        let deviceID = UUID()
        device = CMIOExtensionDevice(
            localizedName: "Switchboard Camera",
            deviceID: deviceID,
            legacyDeviceID: nil,
            source: self
        )

        try? device.addStream(stream.stream)
    }

    // MARK: - CMIOExtensionDeviceSource

    var availableProperties: Set<CMIOExtensionProperty> { [] }

    func deviceProperties(forProperties properties: Set<CMIOExtensionProperty>) throws -> CMIOExtensionDeviceProperties {
        CMIOExtensionDeviceProperties(dictionary: [:])
    }

    func setDeviceProperties(_ deviceProperties: CMIOExtensionDeviceProperties) throws {
        // No settable properties
    }
}
