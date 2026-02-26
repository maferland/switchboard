import AVFoundation

struct VideoDevice: Equatable, Identifiable {
    let id: String
    let name: String
    let modelID: String
    let isBuiltIn: Bool

    init(captureDevice: AVCaptureDevice) {
        self.id = captureDevice.uniqueID
        self.name = captureDevice.localizedName
        self.modelID = captureDevice.modelID
        self.isBuiltIn = captureDevice.modelID.lowercased().contains("builtin")
            || captureDevice.localizedName.lowercased().contains("facetime")
    }

    init(id: String, name: String, modelID: String, isBuiltIn: Bool) {
        self.id = id
        self.name = name
        self.modelID = modelID
        self.isBuiltIn = isBuiltIn
    }
}
