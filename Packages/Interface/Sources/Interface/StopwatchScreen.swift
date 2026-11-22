import Core
import Design
import SwiftUI

/// Stopwatch screen: tenths, split times.
struct StopwatchScreen: View {
    @Environment(AppModel.self) private var model
    @Environment(\.isLandscape) private var landscape

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.05)) { k in
            let u = model.clocks.stopwatch
            if landscape {
                HStack(spacing: 22) {
                    display(u, k.date).frame(maxWidth: .infinity, maxHeight: .infinity)
                    VStack(alignment: .leading, spacing: 10) {
                        PageHeader(title: "tab.stopwatch")
                        list(u)
                        Spacer(minLength: 0)
                        buttons(u, height: 56)
                        LandscapeBar()
                    }
                    .frame(width: 320)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
            } else {
                VStack(alignment: .leading, spacing: 14) {
                    PageHeader(title: "tab.stopwatch")
                    Spacer()
                    display(u, k.date).frame(maxWidth: .infinity)
                    Spacer()
                    if u.marks.count > 1 { list(u).frame(maxHeight: 180) }
                    buttons(u, height: 72)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 14)
            }
        }
    }

    private func display(_ u: Stopwatch, _ now: Date) -> some View {
        let z = TimeFormat.tenths(u.elapsed(now))
        return VStack(spacing: 6) {
            HStack(alignment: .lastTextBaseline, spacing: 0) {
                Text(verbatim: z.main)
                Text(verbatim: z.tenths).foregroundStyle(Palette.muted)
            }
            .fontRole(.digits(128))
            .lineLimit(1).minimumScaleFactor(0.4)
            .accessibilityElement(children: .combine)
            if let last = u.lapTimes.last {
                let parts = TimeFormat.tenths(last)
                Text(app: "stopwatch.split \(u.marks.count) \(parts.main + parts.tenths)")
                    .fontRole(.label).allCaps().foregroundStyle(Palette.muted)
            }
        }
    }

    private func list(_ u: Stopwatch) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(Array(u.lapTimes.enumerated().reversed()), id: \.offset) { i, d in
                    let t = TimeFormat.tenths(d)
                    HStack {
                        Text(app: "laps.number \(i + 1)").foregroundStyle(Palette.muted)
                        Spacer()
                        Text(verbatim: t.main + t.tenths)
                    }
                    .fontRole(.label).allCaps()
                    .padding(.vertical, 8)
                    Divider().overlay(Palette.line)
                }
            }
        }
    }

    private func buttons(_ u: Stopwatch, height: CGFloat) -> some View {
        HStack(spacing: 10) {
            if u.isRunning {
                ClockButton(
                    title: "button.lap", background: Palette.button, fontRole: Palette.text, height: height
                ) {
                    model.clocks.stopwatch.lap(.now)
                }
                ClockButton(
                    title: "button.stop", background: Palette.red, fontRole: Palette.ink, height: height
                ) {
                    model.clocks.stopwatch.pause(.now)
                }
            } else {
                ClockButton(
                    title: "button.reset", background: Palette.button, fontRole: Palette.text, height: height
                ) {
                    model.clocks.stopwatch.reset()
                }
                .disabled(!u.hasStarted)
                .opacity(u.hasStarted ? 1 : 0.4)
                ClockButton(
                    title: u.hasStarted ? "button.resume" : "button.start", background: Palette.green,
                    fontRole: Palette.ink, height: height
                ) {
                    model.clocks.stopwatch.start(.now)
                }
            }
        }
    }
}
