import Core
import Design
import SwiftUI

/// Laps mode on the watch: the whole surface is the button.
struct WatchLapsScreen: View {
    @Environment(WatchModel.self) private var model

    var body: some View {
        @Bindable var clocks = model.clocks
        TimelineView(.periodic(from: .now, by: 0.5)) { k in
            let u = clocks.laps
            VStack(spacing: 6) {
                Button {
                    clocks.laps.lap(.now)
                } label: {
                    VStack(spacing: 0) {
                        Text(app: "laps.lap").fontRole(.small).allCaps()
                        Text(verbatim: "\(u.currentLap)").fontRole(.digits(64))
                        Text(verbatim: TimeFormat.short(Int(u.currentLapTime(k.date)))).fontRole(.label)
                    }
                    .frame(maxWidth: .infinity, minHeight: 120)
                    .foregroundStyle(Palette.ink)
                    .background(Palette.blue, in: RoundedRectangle(cornerRadius: 22))
                }
                .buttonStyle(.plain)
                HStack {
                    Button {
                        if u.isRunning { clocks.laps.pause(.now) } else { clocks.laps.reset() }
                    } label: {
                        Image(systemName: u.isRunning ? "pause.fill" : "arrow.counterclockwise")
                    }
                    .accessibilityLabel(Text(app: u.isRunning ? "button.pause" : "button.reset"))
                    .disabled(!u.hasStarted)
                    if u.hasStarted && !u.isRunning {
                        Button {
                            clocks.laps.resume(.now)
                        } label: {
                            Image(systemName: "play.fill")
                        }
                        .accessibilityLabel(Text(app: "button.resume"))
                    }
                }
            }
        }
        .navigationTitle(Text(app: "tab.laps"))
    }
}

/// Stopwatch on the watch.
struct WatchStopwatchScreen: View {
    @Environment(WatchModel.self) private var model

    var body: some View {
        @Bindable var clocks = model.clocks
        TimelineView(.periodic(from: .now, by: 0.1)) { k in
            let u = clocks.stopwatch
            let z = TimeFormat.tenths(u.elapsed(k.date))
            VStack(spacing: 8) {
                HStack(alignment: .lastTextBaseline, spacing: 0) {
                    Text(verbatim: z.main)
                    Text(verbatim: z.tenths).foregroundStyle(Palette.muted)
                }
                .fontRole(.digits(52))
                .lineLimit(1).minimumScaleFactor(0.5)
                .accessibilityElement(children: .combine)
                HStack {
                    Button {
                        if u.isRunning { clocks.stopwatch.lap(.now) } else { clocks.stopwatch.reset() }
                    } label: {
                        Text(app: u.isRunning ? "button.lap" : "button.reset").fontRole(.small).allCaps()
                    }
                    .disabled(!u.hasStarted)
                    Button {
                        if u.isRunning { clocks.stopwatch.pause(.now) } else { clocks.stopwatch.start(.now) }
                    } label: {
                        Text(
                            app: u.isRunning
                                ? "button.stop" : (u.hasStarted ? "button.resume" : "button.start")
                        )
                        .fontRole(.small).allCaps()
                    }
                    .tint(u.isRunning ? Palette.red : Palette.green)
                }
            }
        }
        .navigationTitle(Text(app: "tab.stopwatch"))
    }
}
