import Testing
@testable import Switchboard

@Suite("RuleEngine")
struct RuleEngineTests {
    let defaultConfig = SwitchboardConfig()

    // MARK: - Test Fixtures

    static let builtInMic = AudioDevice(
        id: 1, name: "MacBook Pro Microphone", uid: "builtin-mic",
        transport: .builtIn, hasInput: true, hasOutput: false
    )

    static let builtInSpeaker = AudioDevice(
        id: 2, name: "MacBook Pro Speakers", uid: "builtin-speaker",
        transport: .builtIn, hasInput: false, hasOutput: true
    )

    static let streamCamAudio = AudioDevice(
        id: 3, name: "Logi StreamCam", uid: "streamcam-audio",
        transport: .usb, hasInput: true, hasOutput: false
    )

    static let airpods = AudioDevice(
        id: 4, name: "AirPods Pro", uid: "airpods",
        transport: .bluetooth, hasInput: true, hasOutput: true
    )

    static let headphones = AudioDevice(
        id: 5, name: "External Headphones", uid: "headphones",
        transport: .bluetooth, hasInput: false, hasOutput: true
    )

    static let builtInCam = VideoDevice(
        id: "builtin-cam", name: "FaceTime HD Camera",
        modelID: "UVC Camera VendorID_1452 ProductID_34068 BuiltIn",
        isBuiltIn: true
    )

    static let streamCam = VideoDevice(
        id: "streamcam", name: "Logi StreamCam",
        modelID: "UVC Camera VendorID_1133", isBuiltIn: false
    )

    func makeState(
        clamshell: ClamshellState = .open,
        audio: [AudioDevice] = [],
        video: [VideoDevice] = [],
        overrides: [DeviceCategory: String] = [:]
    ) -> DeviceState {
        DeviceState(
            clamshellState: clamshell,
            audioDevices: audio,
            videoDevices: video,
            currentDefaults: CurrentDefaults(inputDeviceID: nil, outputDeviceID: nil),
            overrides: overrides
        )
    }

    // MARK: - Laptop Mode

    @Test("Laptop open → built-in mic + built-in cam")
    func laptopOpenBuiltIn() {
        let engine = RuleEngine(config: defaultConfig)
        let state = makeState(
            clamshell: .open,
            audio: [Self.builtInMic, Self.builtInSpeaker, Self.streamCamAudio],
            video: [Self.builtInCam, Self.streamCam]
        )

        let selection = engine.evaluate(state: state)

        #expect(selection.preferredMic?.name == "MacBook Pro Microphone")
        #expect(selection.preferredCamera?.name == "FaceTime HD Camera")
        #expect(selection.reason == "Laptop Mode")
    }

    // MARK: - Clamshell Mode

    @Test("Clamshell + StreamCam → StreamCam mic + cam")
    func clamshellWithStreamCam() {
        let engine = RuleEngine(config: defaultConfig)
        let state = makeState(
            clamshell: .closed,
            audio: [Self.builtInMic, Self.builtInSpeaker, Self.streamCamAudio],
            video: [Self.builtInCam, Self.streamCam]
        )

        let selection = engine.evaluate(state: state)

        #expect(selection.preferredMic?.name == "Logi StreamCam")
        #expect(selection.preferredCamera?.name == "Logi StreamCam")
        #expect(selection.reason == "Clamshell Mode")
    }

    @Test("Clamshell, no StreamCam → built-in mic + external cam")
    func clamshellNoStreamCam() {
        let externalCam = VideoDevice(
            id: "ext-cam", name: "USB Webcam",
            modelID: "UVC Camera", isBuiltIn: false
        )
        let engine = RuleEngine(config: defaultConfig)
        let state = makeState(
            clamshell: .closed,
            audio: [Self.builtInMic, Self.builtInSpeaker],
            video: [Self.builtInCam, externalCam]
        )

        let selection = engine.evaluate(state: state)

        #expect(selection.preferredMic?.name == "MacBook Pro Microphone")
        #expect(selection.preferredCamera?.name == "USB Webcam")
    }

    // MARK: - Blocked Devices

    @Test("AirPods mic is blocked")
    func airpodsMicBlocked() {
        let engine = RuleEngine(config: defaultConfig)
        let state = makeState(
            clamshell: .open,
            audio: [Self.builtInMic, Self.airpods]
        )

        let selection = engine.evaluate(state: state)

        #expect(selection.preferredMic?.name == "MacBook Pro Microphone")
        #expect(selection.preferredMic?.name != "AirPods Pro")
    }

    @Test("Laptop speakers blocked by default")
    func laptopSpeakersBlocked() {
        let engine = RuleEngine(config: defaultConfig)
        let state = makeState(
            clamshell: .open,
            audio: [Self.builtInMic, Self.builtInSpeaker, Self.headphones]
        )

        let selection = engine.evaluate(state: state)

        #expect(selection.preferredOutput?.name == "External Headphones")
    }

    // MARK: - Overrides

    @Test("Manual override takes precedence")
    func manualOverride() {
        let engine = RuleEngine(config: defaultConfig)
        let state = makeState(
            clamshell: .open,
            audio: [Self.builtInMic, Self.streamCamAudio],
            overrides: [.mic: "Logi StreamCam"]
        )

        let selection = engine.evaluate(state: state)

        #expect(selection.preferredMic?.name == "Logi StreamCam")
    }

    // MARK: - Output Priority

    @Test("Headphones preferred over HDMI")
    func headphonesOverHDMI() {
        let hdmi = AudioDevice(
            id: 10, name: "DELL Monitor", uid: "hdmi",
            transport: .hdmi, hasInput: false, hasOutput: true
        )
        let engine = RuleEngine(config: defaultConfig)
        let state = makeState(
            clamshell: .closed,
            audio: [Self.builtInSpeaker, hdmi, Self.headphones]
        )

        let selection = engine.evaluate(state: state)

        #expect(selection.preferredOutput?.name == "External Headphones")
    }

    // MARK: - Mode Description

    @Test(
        "Mode description",
        arguments: [
            (ClamshellState.open, "Laptop Mode"),
            (ClamshellState.closed, "Clamshell Mode"),
        ]
    )
    func modeDescription(clamshell: ClamshellState, expected: String) {
        let engine = RuleEngine(config: defaultConfig)
        let state = makeState(clamshell: clamshell, audio: [Self.builtInMic])
        let selection = engine.evaluate(state: state)
        #expect(selection.reason == expected)
    }
}
