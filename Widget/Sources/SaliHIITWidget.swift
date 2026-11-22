import Design
import SwiftUI
import WidgetKit

@main
struct SaliHIITWidgets: WidgetBundle {
    init() {
        MainActor.assumeIsolated { FontRole.register() }
    }

    var body: some Widget {
        TrainingIsland()
    }
}
