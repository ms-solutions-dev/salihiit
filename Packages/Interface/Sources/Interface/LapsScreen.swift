import Core
import Design
import SwiftUI

/// Laps screen: a large surface to tap, time per lap, best one marked.
struct LapsScreen: View {
    @Environment(AppModel.self) private var model
    @Environment(\.isLandscape) private var landscape

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.1)) { k in
            let u = model.clocks.laps
            if landscape {
                // In landscape the tap surface on the left, list and buttons on the right.
                HStack(spacing: 22) {
                    surface(u, k.date, height: 0)
                    VStack(alignment: .leading, spacing: 10) {
                        PageHeader(title: "tab.laps")
                        total(u, k.date)
                        list(u)
                        buttons(u, height: 56)
                        LandscapeBar()
                    }
                    .frame(width: 320)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
            } else {
                VStack(alignment: .leading, spacing: 14) {
                    PageHeader(title: "tab.laps")
                    total(u, k.date)
                    surface(u, k.date, height: 300)
                    list(u)
                    buttons(u, height: 72)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 14)
            }
        }
    }

    private func total(_ u: Stopwatch, _ now: Date) -> some View {
        HStack {
            Text(app: "editor.total").foregroundStyle(Palette.muted)
            Spacer()
            Text(verbatim: TimeFormat.short(Int(u.elapsed(now))))
        }
        .fontRole(.label).allCaps()
    }

    private func surface(_ u: Stopwatch, _ now: Date, height: CGFloat) -> some View {
        Button {
            model.clocks.laps.lap(.now)
        } label: {
            VStack(spacing: 0) {
                Text(app: "laps.lap").fontRole(.label).allCaps()
                Text(verbatim: "\(u.currentLap)").fontRole(.digits(150)).lineLimit(1)
                    .minimumScaleFactor(0.4)
                Text(verbatim: TimeFormat.short(Int(u.currentLapTime(now)))).fontRole(.card)
                Text(app: u.hasStarted ? "laps.tapToLap" : "laps.tapToStart").fontRole(.label)
                    .allCaps()
                    .padding(.top, 4)
            }
            .frame(maxWidth: .infinity, minHeight: height, maxHeight: height == 0 ? .infinity : nil)
            .foregroundStyle(Palette.ink)
            .background(
                Palette.blue.opacity(u.isRunning || !u.hasStarted ? 1 : 0.5),
                in: RoundedRectangle(cornerRadius: 28))
        }
        .buttonStyle(.plain)
        .disabled(u.hasStarted && !u.isRunning)
    }

    private func list(_ u: Stopwatch) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(Array(u.lapTimes.enumerated().reversed()), id: \.offset) { i, z in
                    HStack {
                        Text(app: "laps.number \(i + 1)").foregroundStyle(Palette.muted)
                        Spacer()
                        if i == u.best {
                            Text(app: "laps.best").foregroundStyle(Palette.green)
                        }
                        Text(verbatim: TimeFormat.short(Int(z.rounded())))
                            .foregroundStyle(i == u.best ? Palette.green : Palette.text)
                    }
                    .fontRole(.label).allCaps()
                    .padding(.vertical, 9)
                    Divider().overlay(Palette.line)
                }
            }
        }
    }

    @ViewBuilder private func buttons(_ u: Stopwatch, height: CGFloat) -> some View {
        if u.hasStarted {
            HStack(spacing: 10) {
                ClockButton(
                    title: "button.reset", background: Palette.button, fontRole: Palette.text, height: height
                ) {
                    model.clocks.laps.reset()
                }
                .disabled(u.isRunning)
                .opacity(u.isRunning ? 0.4 : 1)
                ClockButton(
                    title: u.isRunning ? "button.pause" : "button.resume", background: Palette.text,
                    fontRole: Palette.ink, height: height
                ) {
                    if u.isRunning {
                        model.clocks.laps.pause(.now)
                    } else {
                        model.clocks.laps.resume(.now)
                    }
                }
            }
        }
    }
}

/// A wide capsule button for laps and stopwatch.
struct ClockButton: View {
    let title: LocalizedStringKey
    let background: Color
    let fontRole: Color
    var height: CGFloat = 72
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            // In landscape the button is only 150 pt wide; "Reset" otherwise wrapped in the middle of a word.
            Text(app: title).fontRole(.button).allCaps()
                .lineLimit(1).minimumScaleFactor(0.6)
                .padding(.horizontal, 10)
                .frame(maxWidth: .infinity, minHeight: height)
                .foregroundStyle(fontRole)
                .background(background, in: Capsule())
        }
        .buttonStyle(.plain)
    }
}
