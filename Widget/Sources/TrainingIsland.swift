import ActivityKit
import AppIntents
import Core
import Design
import SwiftUI
import WidgetKit

/// Live Activity and Dynamic Island: phase color, counter, digits, pause and skip.
struct TrainingIsland: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TrainingActivity.self) { k in
            LockScreenCard(state: k.state, template: k.attributes.template)
                .activityBackgroundTint(Palette.background)
                .activitySystemActionForegroundColor(Palette.text)
        } dynamicIsland: { k in
            let s = k.state
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(app: s.kind.shortTitle).fontRole(.label).allCaps()
                        RoundCounter(state: s).fontRole(.small).foregroundStyle(Palette.muted)
                    }
                    .foregroundStyle(Palette.fill(s.kind))
                    .padding(.leading, 6)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Buttons(state: s).padding(.trailing, 6)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 6) {
                        Digits(state: s, size: 64).foregroundStyle(Palette.fill(s.kind))
                        UpNext(state: s).fontRole(.small).foregroundStyle(Palette.muted)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 6)
                }
            } compactLeading: {
                Text(app: s.kind.shortTitle).fontRole(.label).allCaps()
                    .foregroundStyle(Palette.fill(s.kind))
            } compactTrailing: {
                Digits(state: s, size: 18).foregroundStyle(Palette.fill(s.kind))
                    .frame(maxWidth: 52)
            } minimal: {
                Digits(state: s, size: 14).foregroundStyle(Palette.fill(s.kind))
            }
            .keylineTint(Palette.fill(s.kind))
        }
    }
}

/// The lock-screen card: the phase in its color on the left, the buttons on the right.
private struct LockScreenCard: View {
    let state: IslandState
    let template: String

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(app: state.kind.shortTitle)
                    if let u = state.exercise { Text(verbatim: "· " + u).lineLimit(1) }
                    Spacer()
                    RoundCounter(state: state)
                }
                .fontRole(.label).allCaps()
                Digits(state: state, size: 66)
                UpNext(state: state).fontRole(.small).allCaps()
            }
            .foregroundStyle(Palette.ink)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.fill(state.kind))

            Buttons(state: state)
                .frame(width: 76)
        }
        .accessibilityElement(children: .contain)
    }
}

/// "R 2/4 · Z 1/3"
private struct RoundCounter: View {
    let state: IslandState

    var body: some View {
        if state.circuitTotal > 1 {
            Text(verbatim: "R \(state.round)/\(state.rounds) · Z \(state.circuit)/\(state.circuitTotal)")
        } else {
            Text(verbatim: "\(state.round)/\(state.rounds)")
        }
    }
}

/// Counts down on its own until the phase ends; while paused it shows the remaining time.
private struct Digits: View {
    let state: IslandState
    let size: CGFloat

    var body: some View {
        Group {
            if let end = state.phaseEnd {
                Text(timerInterval: state.phaseStart...end, countsDown: true, showsHours: false)
            } else {
                Text(verbatim: TimeFormat.short(state.remainingSeconds))
            }
        }
        .fontRole(.digits(size))
        .lineLimit(1)
        .minimumScaleFactor(0.6)
    }
}

private struct UpNext: View {
    let state: IslandState

    var body: some View {
        if state.isPaused {
            Text(app: "run.paused")
        } else if let n = state.nextKind {
            Text(app: "run.next \(n.titleText + " " + TimeFormat.short(state.nextDuration))")
        } else {
            Text(app: "run.next.done")
        }
    }
}

private struct Buttons: View {
    let state: IslandState

    var body: some View {
        VStack(spacing: 10) {
            if state.isPaused {
                Button(intent: ResumeIntent()) { Image(systemName: "play.fill") }
                    .buttonStyle(IslandButtonStyle(isLight: true))
                    .accessibilityLabel(Text(app: "button.resume"))
            } else {
                Button(intent: PauseIntent()) { Image(systemName: "pause.fill") }
                    .buttonStyle(IslandButtonStyle(isLight: true))
                    .accessibilityLabel(Text(app: "button.pause"))
            }
            Button(intent: SkipIntent()) { Image(systemName: "forward.end.fill") }
                .buttonStyle(IslandButtonStyle(isLight: false))
                .accessibilityLabel(Text(app: "button.skip"))
        }
    }
}

private struct IslandButtonStyle: ButtonStyle {
    let isLight: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .bold))
            .frame(width: 48, height: 48)
            .foregroundStyle(isLight ? Palette.ink : Palette.text)
            .background(isLight ? Palette.text : Palette.button, in: Circle())
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}
