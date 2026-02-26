import Testing
@testable import Switchboard

@Suite("ClamshellDetector")
struct ClamshellDetectorTests {
    @Test("Static detection returns a valid state")
    func detectReturnsValidState() {
        let state = ClamshellDetector.detectClamshellState()

        // On any machine, we should get either .open or .closed
        #expect(state == .open || state == .closed)
    }

    @Test("isBuiltInDisplayActive returns boolean")
    func builtInDisplayCheck() {
        // Just verify it doesn't crash — actual value depends on hardware
        let active = ClamshellDetector.isBuiltInDisplayActive()
        #expect(active == true || active == false)
    }

    @Test("ClamshellState enum cases")
    func clamshellStateCases() {
        let open = ClamshellState.open
        let closed = ClamshellState.closed

        #expect(open != closed)
    }
}
