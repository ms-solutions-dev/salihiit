import Design
import SwiftUI
import UIKit

/// The three modes: interval · laps · stopwatch.
public enum Mode: String, CaseIterable, Identifiable, Sendable {
    case interval, laps, stopwatch
    public var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .interval: "tab.interval"
        case .laps: "tab.laps"
        case .stopwatch: "tab.stopwatch"
        }
    }
}

/// The frame of the app: one screen per mode and the pill bar at the bottom.
///
/// No system tab bar, because the design uses a slim bar in Barlow Condensed and the run screen
/// covers it completely anyway.
public struct MainView: View {
    @Environment(\.verticalSizeClass) private var height
    @Bindable var model: AppModel

    public init(model: AppModel) {
        self.model = model
    }

    public var body: some View {
        VStack(spacing: 0) {
            Group {
                switch model.mode {
                case .interval: IntervalScreen()
                case .laps: LapsScreen()
                case .stopwatch: StopwatchScreen()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // In landscape the bar sits inside the screen itself, otherwise it eats an eighth of the height.
            if height != .compact {
                ModeBar(mode: $model.mode)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
            }
        }
        .background(Palette.background)
        .foregroundStyle(Palette.text)
        .tint(Palette.green)
        .preferredColorScheme(.dark)
        .fullScreenCover(isPresented: Binding(get: { model.training.showsTraining }, set: { _ in })) {
            Group {
                if let run = model.training.run {
                    RunScreen(run: run)
                } else if let e = model.training.summary {
                    SummaryScreen(summary: e)
                }
            }
            .environment(model)
            .preferredColorScheme(.dark)
        }
        .sheet(isPresented: $model.isSettingsOpen) {
            SettingsScreen().environment(model)
        }
        .environment(model)
        .task { await model.requestPermission() }
        #if DEBUG
            .onAppear {
                let screen = ProcessInfo.processInfo.environment["SALIHIIT_SCREEN"]
                if let m = screen.flatMap(Mode.init) { model.mode = m }
                if screen == "settings" || screen == "voices" { model.isSettingsOpen = true }
                // `SIMCTL_CHILD_SALIHIIT_LANDSCAPE=1`: screenshots in landscape, simctl cannot rotate.
                if ProcessInfo.processInfo.environment["SALIHIIT_LANDSCAPE"] == "1",
                    let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
                {
                    scene.requestGeometryUpdate(.iOS(interfaceOrientations: .landscapeRight))
                }
            }
        #endif
    }
}

/// The pill bar at the bottom: the selected mode has a white background.
struct ModeBar: View {
    @Binding var mode: Mode
    var height: CGFloat = 48

    var body: some View {
        // Three words side by side: from AX2 on they would wrap in the middle of a word.
        HStack(spacing: 6) {
            ForEach(Mode.allCases) { m in
                Button {
                    mode = m
                } label: {
                    Text(app: m.title)
                        .fontRole(.label)
                        .allCaps()
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .frame(maxWidth: .infinity, minHeight: height)
                        .foregroundStyle(m == mode ? Palette.ink : Palette.muted)
                        .background(m == mode ? Palette.text : .clear, in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(m == mode ? .isSelected : [])
            }
        }
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }
}

/// The mode bar for landscape, connected to the model.
struct LandscapeBar: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var m = model
        ModeBar(mode: $m.mode, height: 40)
    }
}
