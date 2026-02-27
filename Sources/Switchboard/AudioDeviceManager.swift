import CoreAudio
import Combine
import Foundation

final class AudioDeviceManager {
    let devicesChanged = PassthroughSubject<Void, Never>()
    let defaultInputChanged = PassthroughSubject<AudioObjectID, Never>()
    let defaultOutputChanged = PassthroughSubject<AudioObjectID, Never>()

    private var deviceListListenerBlock: AudioObjectPropertyListenerBlock?
    private var defaultInputListenerBlock: AudioObjectPropertyListenerBlock?
    private var defaultOutputListenerBlock: AudioObjectPropertyListenerBlock?
    private let listenerQueue = DispatchQueue(label: "com.maferland.switchboard.audio")

    init() {
        startListening()
    }

    deinit {
        stopListening()
    }

    // MARK: - Device Enumeration

    func allDevices() -> [AudioDevice] {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var dataSize: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(
            AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &dataSize
        ) == noErr else { return [] }

        let count = Int(dataSize) / MemoryLayout<AudioObjectID>.size
        var deviceIDs = [AudioObjectID](repeating: 0, count: count)

        guard AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &dataSize, &deviceIDs
        ) == noErr else { return [] }

        return deviceIDs.compactMap { buildDevice(id: $0) }
    }

    func inputDevices() -> [AudioDevice] {
        physicalDevices().filter(\.hasInput)
    }

    func outputDevices() -> [AudioDevice] {
        physicalDevices().filter(\.hasOutput)
    }

    func physicalDevices() -> [AudioDevice] {
        allDevices().filter { $0.transport != .virtual && $0.transport != .aggregate }
    }

    // MARK: - Default Device

    func defaultInputDeviceID() -> AudioObjectID? {
        getDefaultDevice(selector: kAudioHardwarePropertyDefaultInputDevice)
    }

    func defaultOutputDeviceID() -> AudioObjectID? {
        getDefaultDevice(selector: kAudioHardwarePropertyDefaultOutputDevice)
    }

    func currentDefaults() -> CurrentDefaults {
        CurrentDefaults(
            inputDeviceID: defaultInputDeviceID(),
            outputDeviceID: defaultOutputDeviceID()
        )
    }

    // MARK: - Set Default

    func setDefaultInput(_ deviceID: AudioObjectID) -> Bool {
        setDefaultDevice(deviceID, selector: kAudioHardwarePropertyDefaultInputDevice)
    }

    func setDefaultOutput(_ deviceID: AudioObjectID) -> Bool {
        setDefaultDevice(deviceID, selector: kAudioHardwarePropertyDefaultOutputDevice)
    }

    // MARK: - Private — Build Device

    private func buildDevice(id: AudioObjectID) -> AudioDevice? {
        guard let name = getStringProperty(id, selector: kAudioObjectPropertyName),
              let uid = getStringProperty(id, selector: kAudioDevicePropertyDeviceUID)
        else { return nil }

        let transport = getTransportType(id)
        let inputChannels = getChannelCount(id, scope: kAudioDevicePropertyScopeInput)
        let outputChannels = getChannelCount(id, scope: kAudioDevicePropertyScopeOutput)

        return AudioDevice(
            id: id,
            name: name,
            uid: uid,
            transport: AudioDeviceTransport(transportType: transport),
            hasInput: inputChannels > 0,
            hasOutput: outputChannels > 0
        )
    }

    private func getStringProperty(_ deviceID: AudioObjectID, selector: AudioObjectPropertySelector) -> String? {
        var address = AudioObjectPropertyAddress(
            mSelector: selector,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var name: Unmanaged<CFString>?
        var size = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)

        guard AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, &name) == noErr,
              let cfString = name?.takeRetainedValue() else {
            return nil
        }
        return cfString as String
    }

    private func getTransportType(_ deviceID: AudioObjectID) -> UInt32 {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyTransportType,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var transport: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)

        AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, &transport)
        return transport
    }

    private func getChannelCount(_ deviceID: AudioObjectID, scope: AudioObjectPropertyScope) -> Int {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreamConfiguration,
            mScope: scope,
            mElement: kAudioObjectPropertyElementMain
        )

        var dataSize: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(deviceID, &address, 0, nil, &dataSize) == noErr else {
            return 0
        }

        let bufferList = UnsafeMutablePointer<AudioBufferList>.allocate(capacity: 1)
        defer { bufferList.deallocate() }

        guard AudioObjectGetPropertyData(deviceID, &address, 0, nil, &dataSize, bufferList) == noErr else {
            return 0
        }

        let buffers = UnsafeMutableAudioBufferListPointer(bufferList)
        return buffers.reduce(0) { $0 + Int($1.mNumberChannels) }
    }

    private func getDefaultDevice(selector: AudioObjectPropertySelector) -> AudioObjectID? {
        var address = AudioObjectPropertyAddress(
            mSelector: selector,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var deviceID: AudioObjectID = 0
        var size = UInt32(MemoryLayout<AudioObjectID>.size)

        guard AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &deviceID
        ) == noErr, deviceID != kAudioObjectUnknown else { return nil }

        return deviceID
    }

    @discardableResult
    private func setDefaultDevice(_ deviceID: AudioObjectID, selector: AudioObjectPropertySelector) -> Bool {
        var address = AudioObjectPropertyAddress(
            mSelector: selector,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var id = deviceID
        let size = UInt32(MemoryLayout<AudioObjectID>.size)

        return AudioObjectSetPropertyData(
            AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, size, &id
        ) == noErr
    }

    // MARK: - Listeners

    private func startListening() {
        var devicesAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        deviceListListenerBlock = { [weak self] _, _ in
            self?.devicesChanged.send()
        }
        AudioObjectAddPropertyListenerBlock(
            AudioObjectID(kAudioObjectSystemObject), &devicesAddress,
            listenerQueue, deviceListListenerBlock!
        )

        var inputAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        defaultInputListenerBlock = { [weak self] _, _ in
            guard let self, let id = self.defaultInputDeviceID() else { return }
            self.defaultInputChanged.send(id)
        }
        AudioObjectAddPropertyListenerBlock(
            AudioObjectID(kAudioObjectSystemObject), &inputAddress,
            listenerQueue, defaultInputListenerBlock!
        )

        var outputAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        defaultOutputListenerBlock = { [weak self] _, _ in
            guard let self, let id = self.defaultOutputDeviceID() else { return }
            self.defaultOutputChanged.send(id)
        }
        AudioObjectAddPropertyListenerBlock(
            AudioObjectID(kAudioObjectSystemObject), &outputAddress,
            listenerQueue, defaultOutputListenerBlock!
        )
    }

    private func stopListening() {
        var devicesAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        if let block = deviceListListenerBlock {
            AudioObjectRemovePropertyListenerBlock(
                AudioObjectID(kAudioObjectSystemObject), &devicesAddress, listenerQueue, block
            )
        }

        var inputAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        if let block = defaultInputListenerBlock {
            AudioObjectRemovePropertyListenerBlock(
                AudioObjectID(kAudioObjectSystemObject), &inputAddress, listenerQueue, block
            )
        }

        var outputAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        if let block = defaultOutputListenerBlock {
            AudioObjectRemovePropertyListenerBlock(
                AudioObjectID(kAudioObjectSystemObject), &outputAddress, listenerQueue, block
            )
        }
    }
}
