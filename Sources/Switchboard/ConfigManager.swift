import Foundation
import Combine

final class ConfigManager {
    private(set) var config: SwitchboardConfig
    private let configURL: URL
    let configChanged = PassthroughSubject<SwitchboardConfig, Never>()

    static let defaultDirectory: URL = {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home.appendingPathComponent(".config/switchboard", isDirectory: true)
    }()

    static let defaultConfigURL: URL = {
        defaultDirectory.appendingPathComponent("config.json")
    }()

    var isFirstLaunch: Bool {
        !FileManager.default.fileExists(atPath: configURL.path)
    }

    init(configURL: URL = ConfigManager.defaultConfigURL) {
        self.configURL = configURL
        self.config = SwitchboardConfig()
        load()
    }

    // MARK: - Load / Save

    func load() {
        guard FileManager.default.fileExists(atPath: configURL.path),
              let data = try? Data(contentsOf: configURL),
              let decoded = try? JSONDecoder().decode(SwitchboardConfig.self, from: data)
        else { return }

        config = decoded
    }

    func save() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        guard let data = try? encoder.encode(config) else { return }

        try? FileManager.default.createDirectory(
            at: configURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try? data.write(to: configURL, options: .atomic)
    }

    func update(_ transform: (inout SwitchboardConfig) -> Void) {
        transform(&config)
        save()
        configChanged.send(config)
    }

    func reset() {
        config = SwitchboardConfig()
        save()
        configChanged.send(config)
    }
}
