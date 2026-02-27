import Foundation

struct SwitchboardConfig: Codable, Equatable {
    var laptopMic: [String] = []
    var laptopOutput: [String] = []
    var laptopCamera: [String] = []
    var clamshellMic: [String] = []
    var clamshellOutput: [String] = []
    var clamshellCamera: [String] = []
}
