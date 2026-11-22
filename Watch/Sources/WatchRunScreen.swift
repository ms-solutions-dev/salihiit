import Core
import Design
import SwiftUI

/// Watch run screen: phase color with timer; swipe left for controls and heart rate.
struct WatchRunScreen: View {
    @Environment(WatchModel.self) private var model
    @Environment(\.isLuminanceReduced) private var dimmed
    let run: Timekeeper
    @State private var screen = 0

    var body: some View {
        TabView(selection: $screen) {
            display.tag(0)
            controls.tag(1)
        }
        .tabViewStyle(.page)
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: Display

    private var display: some View {
        // Aligned to the workout start so digits, haptics and sound land on the same second.
        TimelineView(.periodic(from: run.date(for: 0), by: dimmed ? 1 : 0.2)) { k in
            let z = run.state(k.date)
            let color = Palette.fill(z.phase?.kind ?? .cooldown)
            VStack(spacing: 2) {
                if let p = z.phase {
                    Text(verbatim: counter(p)).fontRole(.small).allCaps()
                }
                Spacer(minLength: 0)
                if run.pausedSince != nil && !dimmed { PauseGlyph(height: 22) }
                Text(app: z.phase?.kind.shortTitle ?? "summary.done").fontRole(.label).allCaps()
                if z.phase?.kind == .active, let u = z.phase?.exercise {
                    Text(verbatim: u).fontRole(.label).allCaps().lineLimit(1).minimumScaleFactor(0.6)
                }
                Text(verbatim: TimeFormat.short(z.remainingSeconds))
                    .fontRole(.digits(78))
                    .lineLimit(1).minimumScaleFactor(0.5)
                Spacer(minLength: 0)
                if run.pausedSince != nil {
                    Text(app: "run.paused").fontRole(.small).allCaps()
                } else if let n = z.next {
                    Text(app: "run.next \(n.kind.titleText + " " + TimeFormat.short(n.duration))")
                        .fontRole(.small).allCaps().lineLimit(1).minimumScaleFactor(0.7)
                }
            }
            .foregroundStyle(dimmed ? color : Palette.ink)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                Group {
                    if dimmed {
                        Palette.background
                    } else if run.pausedSince != nil {
                        PausedStripes(color: color, width: 10)
                    } else {
                        color
                    }
                }
                .ignoresSafeArea()
            }
            .onChange(of: z.finished) { _, finished in
                if finished { model.training.end() }
            }
            .accessibilityElement(children: .combine)
        }
    }

    private func counter(_ p: Phase) -> String {
        run.plan.circuits > 1
            ? "R \(p.round)/\(run.plan.rounds) · Z \(p.circuit)/\(run.plan.circuits)"
            : "R \(p.round)/\(run.plan.rounds)"
    }

    // MARK: Controls

    private var controls: some View {
        TimelineView(.periodic(from: .now, by: 1)) { k in
            let z = run.state(k.date)
            VStack(spacing: 8) {
                HStack {
                    Text(app: "watch.heartRate").foregroundStyle(Palette.muted)
                    Spacer()
                    Text(verbatim: model.heartRate.map { "\($0)" } ?? "–").foregroundStyle(Palette.heartRate)
                }
                .fontRole(.label).allCaps()
                HStack {
                    Text(app: "watch.remaining").foregroundStyle(Palette.muted)
                    Spacer()
                    Text(verbatim: TimeFormat.short(z.totalRemainingSeconds))
                }
                .fontRole(.label).allCaps()
                Spacer(minLength: 0)
                Button {
                    model.training.perform(run.isRunning ? .pause : .resume)
                    screen = 0
                } label: {
                    Text(app: run.isRunning ? "button.pause" : "button.resume").fontRole(.label).allCaps()
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.borderedProminent)
                .tint(Palette.text)
                .foregroundStyle(Palette.ink)
                HStack {
                    Button {
                        model.training.end()
                    } label: {
                        Image(systemName: "stop.fill").frame(maxWidth: .infinity, minHeight: 36)
                    }
                    .accessibilityLabel(Text(app: "button.end"))
                    Button {
                        model.training.perform(.skip)
                        screen = 0
                    } label: {
                        Image(systemName: "forward.end.fill").frame(maxWidth: .infinity, minHeight: 36)
                    }
                    .accessibilityLabel(Text(app: "button.skip"))
                }
            }
            .padding(.horizontal, 4)
        }
    }
}

/// Watch summary screen.
struct WatchSummaryScreen: View {
    @Environment(WatchModel.self) private var model
    let summary: WorkoutSummary

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text(app: "summary.done").fontRole(.digits(44)).allCaps().foregroundStyle(Palette.green)
                row("summary.time", TimeFormat.short(summary.duration))
                row("summary.rounds", "\(summary.rounds)")
                if let k = summary.calories { row("summary.calories", "\(k)") }
                if let p = summary.heartRate { row("summary.heartRate", "\(p)") }
                Button {
                    model.training.close()
                } label: {
                    Text(app: "button.close").fontRole(.label).allCaps().frame(maxWidth: .infinity)
                }
                .padding(.top, 6)
            }
        }
    }

    private func row(_ title: LocalizedStringKey, _ value: String) -> some View {
        HStack {
            Text(app: title).foregroundStyle(Palette.muted)
            Spacer()
            Text(verbatim: value)
        }
        .fontRole(.label).allCaps()
    }
}
