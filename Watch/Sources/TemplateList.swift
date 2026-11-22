import Core
import Design
import SwiftUI

/// Watch template list: the templates from the iPhone, below them laps and stopwatch.
struct TemplateList: View {
    @Environment(WatchModel.self) private var model

    var body: some View {
        List {
            ForEach(model.store.templates) { v in
                Button {
                    model.start(v)
                } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(verbatim: v.name).fontRole(.label).allCaps().lineLimit(1)
                            Spacer()
                            Text(verbatim: TimeFormat.short(PhasePlan(v).total)).fontRole(.label)
                        }
                        SequenceBar(plan: PhasePlan(v), height: 6)
                    }
                    .padding(.vertical, 6)
                }
                .listItemTint(Palette.card)
            }
            Section {
                NavigationLink {
                    WatchLapsScreen()
                } label: {
                    Label {
                        Text(app: "tab.laps").fontRole(.label).allCaps()
                    } icon: {
                        Image(systemName: "flag.checkered")
                    }
                }
                NavigationLink {
                    WatchStopwatchScreen()
                } label: {
                    Label {
                        Text(app: "tab.stopwatch").fontRole(.label).allCaps()
                    } icon: {
                        Image(systemName: "stopwatch")
                    }
                }
            }
        }
        .navigationTitle(Text(app: "tab.interval"))
        #if DEBUG
            // For screenshots: `SIMCTL_CHILD_SALIHIIT_SCREEN=run xcrun simctl launch …`
            .onAppear {
                let screen = ProcessInfo.processInfo.environment["SALIHIIT_SCREEN"]
                if screen == "run" || screen == "paused", let v = model.store.selected {
                    model.training.start(v)  // without the Health dialog, which would cover the screenshot
                    if screen == "paused" { model.training.perform(.pause) }
                }
            }
        #endif
    }
}
