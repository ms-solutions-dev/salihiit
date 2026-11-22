import Design
import SwiftUI
import WatchKit

@main
struct SaliHIITWatchApp: App {
    @WKApplicationDelegateAdaptor private var delegate: WatchDelegate
    @State private var model = WatchModel()

    init() {
        FontRole.register()
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                TemplateList()
            }
            .fullScreenCover(isPresented: Binding(get: { model.training.showsTraining }, set: { _ in })) {
                Group {
                    if let run = model.training.run {
                        WatchRunScreen(run: run)
                    } else if let e = model.training.summary {
                        WatchSummaryScreen(summary: e)
                    }
                }
                .environment(model)
            }
            .environment(model)
            .tint(Palette.green)
        }
    }
}
