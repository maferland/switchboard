import Testing
import Foundation
@testable import Switchboard

@Suite("ConfigManager")
struct ConfigManagerTests {
    func makeTempURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("switchboard-test-\(UUID().uuidString)")
            .appendingPathComponent("config.json")
    }

    @Test("Default config has expected values")
    func defaultConfig() {
        let config = SwitchboardConfig()

        #expect(config.blockedMicKeywords == ["AirPods", "Headphone"])
        #expect(config.blockedOutputKeywords == ["MacBook Pro Speakers"])
        #expect(config.allowLaptopSpeakers == false)
        #expect(config.streamCamKeyword == "StreamCam")
        #expect(config.defaultCamera == "built-in")
        #expect(config.defaultMic == "built-in")
    }

    @Test("Save and load round-trips config")
    func saveAndLoad() throws {
        let url = makeTempURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }

        let manager = ConfigManager(configURL: url)
        manager.update {
            $0.streamCamKeyword = "MyWebcam"
            $0.allowLaptopSpeakers = true
            $0.blockedMicKeywords = ["AirPods", "Jabra"]
        }

        // Reload from disk
        let manager2 = ConfigManager(configURL: url)

        #expect(manager2.config.streamCamKeyword == "MyWebcam")
        #expect(manager2.config.allowLaptopSpeakers == true)
        #expect(manager2.config.blockedMicKeywords == ["AirPods", "Jabra"])
    }

    @Test("isFirstLaunch when no config file")
    func firstLaunch() {
        let url = makeTempURL()
        let manager = ConfigManager(configURL: url)

        #expect(manager.isFirstLaunch == true)
    }

    @Test("isFirstLaunch false after save")
    func notFirstLaunchAfterSave() {
        let url = makeTempURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }

        let manager = ConfigManager(configURL: url)
        manager.save()

        #expect(manager.isFirstLaunch == false)
    }

    @Test("Reset restores defaults")
    func reset() {
        let url = makeTempURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }

        let manager = ConfigManager(configURL: url)
        manager.update { $0.streamCamKeyword = "Changed" }
        manager.reset()

        #expect(manager.config.streamCamKeyword == "StreamCam")
    }
}
