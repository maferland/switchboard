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

    @Test("Default config has empty arrays")
    func defaultConfig() {
        let config = SwitchboardConfig()

        #expect(config.laptopMic == [])
        #expect(config.laptopOutput == [])
        #expect(config.laptopCamera == [])
        #expect(config.clamshellMic == [])
        #expect(config.clamshellOutput == [])
        #expect(config.clamshellCamera == [])
    }

    @Test("Save and load round-trips config")
    func saveAndLoad() throws {
        let url = makeTempURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }

        let manager = ConfigManager(configURL: url)
        manager.update {
            $0.clamshellMic = ["Logi StreamCam", "MacBook Pro Microphone"]
            $0.clamshellCamera = ["Logi StreamCam"]
            $0.laptopOutput = ["MacBook Pro Speakers"]
        }

        let manager2 = ConfigManager(configURL: url)

        #expect(manager2.config.clamshellMic == ["Logi StreamCam", "MacBook Pro Microphone"])
        #expect(manager2.config.clamshellCamera == ["Logi StreamCam"])
        #expect(manager2.config.laptopOutput == ["MacBook Pro Speakers"])
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
        manager.update { $0.clamshellMic = ["Changed"] }
        manager.reset()

        #expect(manager.config.clamshellMic == [])
    }
}
