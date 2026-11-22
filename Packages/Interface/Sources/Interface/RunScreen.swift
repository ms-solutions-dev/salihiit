import Core
import Design
import SwiftUI

/// Run screen: the whole screen in the phase color, portrait and landscape.
///
/// The display is recomputed from the timekeeper in every frame; nothing is counted up.
struct RunScreen: View {
    @Environment(AppModel.self) private var model
    let run: Timekeeper
    @State private var confirmEnd = false

    var body: some View {
        // Tick aligned to the start of the workout: the digits jump exactly on the full second in which
        // the number is also spoken. With `from: .now` they jumped up to 100 ms later.
        TimelineView(.periodic(from: run.date(for: 0), by: 0.1)) { context in
            let z = run.state(context.date)
            GeometryReader { geo in
                let landscape = geo.size.width > geo.size.height
                Group {
                    if landscape { landscapeLayout(z) } else { portraitLayout(z) }
                }
                .background(surface(z).ignoresSafeArea())
                .animation(.easeInOut(duration: 0.25), value: z.phase?.kind)
            }
            .onChange(of: z.finished) { _, finished in
                if finished { model.training.end() }
            }
        }
        .foregroundStyle(Palette.ink)
        // From AX2 on the labels would crowd out the digits that matter here.
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        // A white status bar on yellow and green is barely readable; nobody needs it during a workout.
        .statusBarHidden()
        .confirmationDialog(
            Text(app: "run.endConfirm"), isPresented: $confirmEnd, titleVisibility: .visible
        ) {
            Button(role: .destructive) {
                model.training.end()
            } label: {
                Text(app: "button.end")
            }
        }
    }

    // MARK: Portrait

    private func portraitLayout(_ z: DisplayState) -> some View {
        VStack(spacing: 0) {
            header(z).padding(.horizontal, 24).padding(.top, 8)
            Spacer(minLength: 0)
            mid(z, digits: 190)
            Spacer(minLength: 0)
            VStack(alignment: .leading, spacing: 18) {
                upNext(z)
                buttons
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 12)
            .foregroundStyle(Palette.text)
            .background(Palette.background.ignoresSafeArea(edges: .bottom))
        }
    }

    // MARK: Landscape

    private func landscapeLayout(_ z: DisplayState) -> some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    phaseTitle(z).fontRole(.digits(44)).allCaps()
                    if run.pausedSince != nil { PauseGlyph(height: 34) }
                    Spacer()
                    // The same row as in portrait, with duration and next exercise.
                    upNext(z).foregroundStyle(Palette.ink)
                }
                digits(z, size: 240)
                progress(z.progress)
            }
            .padding(.leading, 24)
            .padding(.trailing, 20)
            .frame(maxWidth: .infinity)

            VStack(spacing: 12) {
                counter(z).fontRole(.label).allCaps()
                // "Left" as in portrait; "Total" read like the total duration of the workout.
                HStack {
                    Text(verbatim: run.template.name).lineLimit(1)
                    Spacer()
                    Text(app: "run.remaining \(TimeFormat.short(z.totalRemainingSeconds))")
                }
                .fontRole(.label).allCaps().foregroundStyle(Palette.muted)
                Spacer(minLength: 0)
                pauseButton
                HStack(spacing: 10) {
                    endButton.frame(maxWidth: .infinity)
                    skipButton.frame(maxWidth: .infinity)
                }
            }
            .frame(width: 220)
            .padding(.vertical, 20)
            .padding(.horizontal, 18)
            .foregroundStyle(Palette.text)
            .background(Palette.background.ignoresSafeArea())
        }
    }

    // MARK: Parts

    /// The phase color, striped while paused.
    @ViewBuilder private func surface(_ z: DisplayState) -> some View {
        let color = Palette.fill(z.phase?.kind ?? .cooldown)
        if run.pausedSince != nil {
            PausedStripes(color: color)
        } else {
            color
        }
    }

    private func header(_ z: DisplayState) -> some View {
        VStack(spacing: 6) {
            counter(z).fontRole(.label).allCaps()
            progress(1 - z.totalRemaining / Double(max(run.plan.total, 1)))
            HStack {
                Text(verbatim: run.template.name)
                Spacer()
                Text(app: "run.remaining \(TimeFormat.short(z.totalRemainingSeconds))")
            }
            .fontRole(.small).allCaps()
        }
    }

    private func counter(_ z: DisplayState) -> some View {
        HStack {
            if let p = z.phase {
                Text(app: "run.round \(p.round) \(run.plan.rounds)")
                Spacer()
                if run.plan.circuits > 1 {
                    Text(app: "run.circuit \(p.circuit) \(run.plan.circuits)")
                }
            }
        }
    }

    private func mid(_ z: DisplayState, digits size: CGFloat) -> some View {
        VStack(spacing: 2) {
            if run.pausedSince != nil { PauseGlyph(height: 56).padding(.bottom, 10) }
            phaseTitle(z).fontRole(.digits(48)).allCaps()
            if z.phase?.kind == .active, let u = z.phase?.exercise {
                Text(verbatim: u).fontRole(.digits(52)).allCaps()
                    .lineLimit(1).minimumScaleFactor(0.5)
                    .padding(.horizontal, 20)
            }
            digits(z, size: size)
        }
    }

    private func phaseTitle(_ z: DisplayState) -> Text {
        Text(app: z.phase?.kind.shortTitle ?? "summary.done")
    }

    private func digits(_ z: DisplayState, size: CGFloat) -> some View {
        Text(verbatim: TimeFormat.short(z.remainingSeconds))
            .fontRole(.digits(size))
            .lineLimit(1)
            .minimumScaleFactor(0.3)
            .padding(.horizontal, 12)
            .accessibilityLabel(
                Text(app: "run.announce \(z.phase?.kind.titleText ?? "") \(z.remainingSeconds)"))
    }

    private func progress(_ progress: Double) -> some View {
        GeometryReader { g in
            ZStack(alignment: .leading) {
                Capsule().fill(Palette.track)
                Capsule().fill(Palette.ink).frame(width: g.size.width * min(max(progress, 0), 1))
            }
        }
        .frame(height: 8)
        .accessibilityHidden(true)
    }

    /// "Next: Rest 0:15 · Squats": the next phase and, if named, the next exercise.
    private func upNext(_ z: DisplayState) -> some View {
        HStack(spacing: 10) {
            if let n = z.next, let i = z.index {
                let upcoming = n.kind == .active ? n.exercise : run.plan.after(i + 1)?.exercise
                let phase = n.kind.titleText + " " + TimeFormat.short(n.duration)
                Circle().fill(Palette.fill(n.kind)).frame(width: 14, height: 14)
                if let u = upcoming {
                    Text(app: "run.next.with \(phase) \(u)")
                } else {
                    Text(app: "run.next \(phase)")
                }
            } else {
                Text(app: "run.next.done")
            }
        }
        .fontRole(.label).allCaps()
        .lineLimit(1).minimumScaleFactor(0.7)
    }

    private var buttons: some View {
        HStack(spacing: 10) {
            endButton
            pauseButton
            skipButton
        }
    }

    private var pauseButton: some View {
        Button {
            if run.isRunning {
                model.training.perform(.pause)
            } else {
                model.training.perform(.resume)
            }
        } label: {
            Text(app: run.isRunning ? "button.pause" : "button.resume").fontRole(.button).allCaps()
                .lineLimit(1).minimumScaleFactor(0.6)
                .padding(.horizontal, 10)
                .frame(maxWidth: .infinity, minHeight: 72)
                .foregroundStyle(Palette.ink)
                .background(Palette.text, in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private var endButton: some View {
        circleButton("stop.fill", "button.end") { confirmEnd = true }
    }

    private var skipButton: some View {
        circleButton("forward.end.fill", "button.skip") { model.training.perform(.skip) }
    }

    private func circleButton(
        _ icon: String, _ title: LocalizedStringKey, action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title2)
                .frame(minWidth: 72, minHeight: 72)
                .background(Palette.button, in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(app: title))
    }
}
