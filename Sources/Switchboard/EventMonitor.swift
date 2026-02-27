import Foundation
import Combine

final class EventMonitor {
    private let audioManager: AudioDeviceManager
    private let cameraManager: CameraManager
    private let clamshellDetector: ClamshellDetector
    private let configManager: ConfigManager
    private let deviceController: DeviceController

    private var cancellables = Set<AnyCancellable>()
    private let evaluationQueue = DispatchQueue(label: "com.maferland.switchboard.eval")

    /// Manual overrides — sticky until cleared
    private var overrides: [DeviceCategory: String] = [:]

    var onSelectionChanged: ((DeviceSelection, ClamshellState) -> Void)?

    init(
        audioManager: AudioDeviceManager,
        cameraManager: CameraManager,
        clamshellDetector: ClamshellDetector,
        configManager: ConfigManager,
        deviceController: DeviceController
    ) {
        self.audioManager = audioManager
        self.cameraManager = cameraManager
        self.clamshellDetector = clamshellDetector
        self.configManager = configManager
        self.deviceController = deviceController

        subscribe()
        // Initial evaluation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.evaluateAndApply()
        }
    }

    func setOverride(category: DeviceCategory, deviceName: String?) {
        if let deviceName {
            overrides[category] = deviceName
        } else {
            overrides.removeValue(forKey: category)
        }
        evaluateAndApply()
    }

    // MARK: - Private

    private func subscribe() {
        audioManager.devicesChanged
            .debounce(for: .milliseconds(500), scheduler: evaluationQueue)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.evaluateAndApply() }
            .store(in: &cancellables)

        audioManager.defaultInputChanged
            .debounce(for: .milliseconds(500), scheduler: evaluationQueue)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.evaluateAndApply() }
            .store(in: &cancellables)

        audioManager.defaultOutputChanged
            .debounce(for: .milliseconds(500), scheduler: evaluationQueue)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.evaluateAndApply() }
            .store(in: &cancellables)

        clamshellDetector.statePublisher
            .dropFirst() // skip initial value (we evaluate on init)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.evaluateAndApply() }
            .store(in: &cancellables)

        cameraManager.camerasChanged
            .debounce(for: .milliseconds(500), scheduler: evaluationQueue)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.evaluateAndApply() }
            .store(in: &cancellables)

        // React to config changes — rebuild RuleEngine with new config
        configManager.configChanged
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.evaluateAndApply() }
            .store(in: &cancellables)
    }

    private func evaluateAndApply() {
        let state = DeviceState(
            clamshellState: clamshellDetector.currentState,
            audioDevices: audioManager.allDevices(),
            videoDevices: cameraManager.allCameras(),
            currentDefaults: audioManager.currentDefaults(),
            overrides: overrides
        )

        let ruleEngine = RuleEngine(config: configManager.config)
        let selection = ruleEngine.evaluate(state: state)
        deviceController.apply(selection: selection)
        onSelectionChanged?(selection, state.clamshellState)
    }
}
