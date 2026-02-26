import Foundation
import CoreMediaIO
import CoreMedia
import CoreVideo

final class SwitchboardCameraStream: NSObject, CMIOExtensionStreamSource {
    private(set) var stream: CMIOExtensionStream!

    /// Which real camera to proxy frames from — set by main app via UserDefaults/XPC.
    var sourceCameraID: String? {
        UserDefaults(suiteName: "com.maferland.switchboard.camera")?.string(forKey: "sourceCameraID")
    }

    private let _formats: [CMIOExtensionStreamFormat]

    override init() {
        let formatDescription = SwitchboardCameraStream.makeFormatDescription()
        _formats = [
            CMIOExtensionStreamFormat(
                formatDescription: formatDescription,
                maxFrameDuration: CMTime(value: 1, timescale: 30),
                minFrameDuration: CMTime(value: 1, timescale: 30),
                validFrameDurations: nil
            )
        ]

        super.init()

        let streamID = UUID()
        stream = CMIOExtensionStream(
            localizedName: "Switchboard Camera Stream",
            streamID: streamID,
            direction: .source,
            clockType: .hostTime,
            source: self
        )
    }

    // MARK: - CMIOExtensionStreamSource

    var formats: [CMIOExtensionStreamFormat] { _formats }

    var availableProperties: Set<CMIOExtensionProperty> {
        [.streamActiveFormatIndex, .streamFrameDuration]
    }

    func streamProperties(forProperties properties: Set<CMIOExtensionProperty>) throws -> CMIOExtensionStreamProperties {
        let props = CMIOExtensionStreamProperties(dictionary: [:])

        if properties.contains(.streamActiveFormatIndex) {
            props.activeFormatIndex = 0
        }
        if properties.contains(.streamFrameDuration) {
            props.frameDuration = CMTime(value: 1, timescale: 30)
        }

        return props
    }

    func setStreamProperties(_ streamProperties: CMIOExtensionStreamProperties) throws {}

    func authorizedToStartStream(for client: CMIOExtensionClient) -> Bool { true }

    func startStream() throws {
        // TODO: Open AVCaptureSession on sourceCameraID, forward frames via stream.send()
    }

    func stopStream() throws {
        // TODO: Stop AVCaptureSession
    }

    // MARK: - Private

    private static func makeFormatDescription() -> CMFormatDescription {
        var formatDescription: CMFormatDescription?
        CMVideoFormatDescriptionCreate(
            allocator: kCFAllocatorDefault,
            codecType: kCVPixelFormatType_32BGRA,
            width: 1920,
            height: 1080,
            extensions: nil,
            formatDescriptionOut: &formatDescription
        )
        return formatDescription!
    }
}
