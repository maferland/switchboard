import Foundation
import Combine

final class EventMonitor {
    private let audioManager: AudioDeviceManager
    private let cameraManager: CameraManager
    private let clamshellDetector: ClamshellDetector
    private let ruleEngine: RuleEngine
    private let deviceController: DeviceController
    private let menuBarController: MenuBarController

    private var cancellables = Set<AnyCancellable>()
    private let evaluationQueue = DispatchQueue(label: "com.maferland.switchboard.eval")

    /// Manual overrides — sticky until cleared
    private var overrides: [DeviceCategory: String] = [:]

    init(
        audioManager: AudioDeviceManager,
        cameraManager: CameraManager,
        clamshellDetector: ClamshellDetector,
        ruleEngine: RuleEngine,
        deviceController: DeviceController,
        menuBarController: MenuBarController
    ) {
        self.audioManager = audioManager
        self.cameraManager = cameraManager
        self.clamshellDetector = clamshellDetector
        self.ruleEngine = ruleEngine
        self.deviceController = deviceController
        self.menuBarController = menuBarController

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
        // Audio device list changes
        audioManager.devicesChanged
            .debounce(for: .milliseconds(500), scheduler: evaluationQueue)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.evaluateAndApply() }
            .store(in: &cancellables)

        // Default input changed externally
        audioManager.defaultInputChanged
            .debounce(for: .milliseconds(500), scheduler: evaluationQueue)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.evaluateAndApply() }
            .store(in: &cancellables)

        // Default output changed externally
        audioManager.defaultOutputChanged
            .debounce(for: .milliseconds(500), scheduler: evaluationQueue)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.evaluateAndApply() }
            .store(in: &cancellables)

        // Clamshell state changes
        clamshellDetector.statePublisher
            .dropFirst() // skip initial value (we evaluate on init)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.evaluateAndApply() }
            .store(in: &cancellables)

        // Camera list changes
        cameraManager.camerasChanged
            .debounce(for: .milliseconds(500), scheduler: evaluationQueue)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.evaluateAndApply() }
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

        let selection = ruleEngine.evaluate(state: state)
        deviceController.apply(selection: selection)
        menuBarController.update(selection: selection)
    }
}
