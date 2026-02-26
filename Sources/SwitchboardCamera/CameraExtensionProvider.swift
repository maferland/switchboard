import Foundation
import CoreMediaIO

// NOTE: CMIOExtension requires Xcode for .appex bundling and system extension entitlements.
// This code is the scaffold — it compiles but cannot run as a standalone SPM target.

final class SwitchboardCameraProvider: NSObject, CMIOExtensionProviderSource {
    private(set) var provider: CMIOExtensionProvider!
    private let device: SwitchboardCameraDevice

    init(clientQueue: DispatchQueue) {
        device = SwitchboardCameraDevice()
        super.init()
        provider = CMIOExtensionProvider(source: self, clientQueue: clientQueue)
    }

    // MARK: - CMIOExtensionProviderSource

    var availableProperties: Set<CMIOExtensionProperty> { [] }

    func providerProperties(forProperties properties: Set<CMIOExtensionProperty>) throws -> CMIOExtensionProviderProperties {
        CMIOExtensionProviderProperties(dictionary: [:])
    }

    func setProviderProperties(_ providerProperties: CMIOExtensionProviderProperties) throws {}

    func connect(to client: CMIOExtensionClient) throws {}

    func disconnect(from client: CMIOExtensionClient) {}
}
