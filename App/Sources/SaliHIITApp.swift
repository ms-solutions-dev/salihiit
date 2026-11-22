import Design
import Interface
import SwiftUI

@main
struct SaliHIITApp: App {
    @State private var model = AppModel()
    @Environment(\.scenePhase) private var scene

    init() {
        FontRole.register()
    }

    var body: some Scene {
        WindowGroup {
            MainView(model: model)
        }
        // At scene level: under the full-screen cover the list would not notice the change.
        .onChange(of: scene) { _, new in model.foreground(new == .active) }
    }
}
