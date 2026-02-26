import AVFoundation
import Combine

final class CameraManager {
    let camerasChanged = PassthroughSubject<Void, Never>()

    private var discoverySession: AVCaptureDevice.DiscoverySession?
    private var observation: NSKeyValueObservation?

    init() {
        discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .external],
            mediaType: .video,
            position: .unspecified
        )

        observation = discoverySession?.observe(\.devices, options: [.new]) { [weak self] _, _ in
            self?.camerasChanged.send()
        }
    }

    func allCameras() -> [VideoDevice] {
        (discoverySession?.devices ?? []).map { VideoDevice(captureDevice: $0) }
    }

    func builtInCamera() -> VideoDevice? {
        allCameras().first(where: \.isBuiltIn)
    }

    func externalCameras() -> [VideoDevice] {
        allCameras().filter { !$0.isBuiltIn }
    }

    func camera(named keyword: String) -> VideoDevice? {
        allCameras().first { $0.name.localizedCaseInsensitiveContains(keyword) }
    }
}
