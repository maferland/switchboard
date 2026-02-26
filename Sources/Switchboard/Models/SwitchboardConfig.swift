import Foundation

struct SwitchboardConfig: Codable, Equatable {
    var clamshellCamera: String?
    var clamshellMic: String?
    var defaultCamera: String = "built-in"
    var defaultMic: String = "built-in"
    var blockedMicKeywords: [String] = ["AirPods", "Headphone"]
    var blockedOutputKeywords: [String] = ["MacBook Pro Speakers"]
    var allowLaptopSpeakers: Bool = false
    var streamCamKeyword: String = "StreamCam"
}
