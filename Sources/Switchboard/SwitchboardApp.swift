import SwiftUI

@main
struct SwitchboardApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra {
            MainView(state: appDelegate.windowState)
        } label: {
            Image(systemName: "arrow.triangle.swap")
        }
        .menuBarExtraStyle(.window)
    }
}
