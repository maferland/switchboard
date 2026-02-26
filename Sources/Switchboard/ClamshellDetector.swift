import Foundation
import Combine
import IOKit
import CoreGraphics

final class ClamshellDetector {
    let statePublisher: CurrentValueSubject<ClamshellState, Never>

    private var displayReconfigToken: UnsafeMutableRawPointer?
    private var pollTimer: Timer?

    init() {
        let initial = ClamshellDetector.detectClamshellState()
        statePublisher = CurrentValueSubject(initial)
        startMonitoring()
    }

    deinit {
        stopMonitoring()
    }

    var currentState: ClamshellState {
        statePublisher.value
    }

    // MARK: - Detection Logic

    /// Combines IOKit lid state and display activity.
    /// Clamshell = lid closed OR built-in display inactive.
    static func detectClamshellState() -> ClamshellState {
        if isLidClosed() || !isBuiltInDisplayActive() {
            return .closed
        }
        return .open
    }

    /// IOKit: check AppleSmartBattery/clamshell state
    static func isLidClosed() -> Bool {
        let port: mach_port_t
        if #available(macOS 12.0, *) {
            port = kIOMainPortDefault
        } else {
            port = 0 // kIOMasterPortDefault deprecated
        }

        guard let service = IOServiceGetMatchingService(
            port,
            IOServiceMatching("AppleSmartBattery")
        ).nilIfInvalid() else { return false }

        defer { IOObjectRelease(service) }

        guard let prop = IORegistryEntryCreateCFProperty(
            service,
            "ExternalConnected" as CFString,
            kCFAllocatorDefault,
            0
        ) else { return false }

        // If we can read the registry, try clamshell-specific key
        let clamshellService = IOServiceGetMatchingService(
            port,
            IOServiceMatching("IOPMrootDomain")
        )
        guard clamshellService != IO_OBJECT_NULL else {
            _ = prop // suppress unused warning
            return false
        }
        defer { IOObjectRelease(clamshellService) }

        guard let clamshellProp = IORegistryEntryCreateCFProperty(
            clamshellService,
            "AppleClamshellState" as CFString,
            kCFAllocatorDefault,
            0
        ) else { return false }

        return (clamshellProp.takeRetainedValue() as? Bool) ?? false
    }

    /// CGDisplay: check if built-in display is active
    static func isBuiltInDisplayActive() -> Bool {
        let maxDisplays: UInt32 = 16
        var onlineDisplays = [CGDirectDisplayID](repeating: 0, count: Int(maxDisplays))
        var displayCount: UInt32 = 0

        guard CGGetOnlineDisplayList(maxDisplays, &onlineDisplays, &displayCount) == .success else {
            return true // assume open if we can't check
        }

        for i in 0..<Int(displayCount) {
            let displayID = onlineDisplays[i]
            if CGDisplayIsBuiltin(displayID) != 0 {
                return CGDisplayIsActive(displayID) != 0
            }
        }

        // No built-in display found — likely Mac Mini/Pro, treat as open
        return true
    }

    // MARK: - Monitoring

    private func startMonitoring() {
        // CGDisplay reconfiguration callback
        CGDisplayRegisterReconfigurationCallback({ _, flags, userInfo in
            guard flags.contains(.beginConfigurationFlag) == false else { return }
            guard let detector = userInfo.map({ Unmanaged<ClamshellDetector>.fromOpaque($0).takeUnretainedValue() }) else { return }
            detector.refresh()
        }, Unmanaged.passUnretained(self).toOpaque())

        // Poll IOKit lid state every 5 seconds (IOKit notifications for lid are unreliable)
        pollTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            self?.refresh()
        }
    }

    private func stopMonitoring() {
        CGDisplayRemoveReconfigurationCallback({ _, flags, userInfo in
            // matching callback signature required
        }, Unmanaged.passUnretained(self).toOpaque())

        pollTimer?.invalidate()
        pollTimer = nil
    }

    private func refresh() {
        let newState = ClamshellDetector.detectClamshellState()
        if newState != statePublisher.value {
            print("[Switchboard] Clamshell: \(newState)")
            statePublisher.send(newState)
        }
    }
}

// MARK: - IOKit Helpers

private extension io_object_t {
    func nilIfInvalid() -> io_object_t? {
        self == IO_OBJECT_NULL ? nil : self
    }
}
