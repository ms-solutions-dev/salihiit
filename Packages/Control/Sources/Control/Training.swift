import Core
import Foundation
import Observation
import Signals
import Storage

/// The flow of a workout, identical on phone and watch: run, summary, signals.
///
/// Whatever else needs to follow along (Live Activity, screen, watch link, workout) hooks in via
/// `observe`; this module knows none of them.
@MainActor @Observable public final class Training {
    /// The running workout; `nil` without one.
    public private(set) var run: Timekeeper?
    /// Set after the workout until the summary screen is closed.
    public var summary: WorkoutSummary?

    /// True if the run comes from the other device; then nothing sounds here.
    public private(set) var mirrored = false
    public let settings: SettingsStore
    @ObservationIgnored public let signals: SignalEngine
    @ObservationIgnored private var observers: [(Timekeeper?, ChangeOrigin) -> Void] = []

    /// Where a change comes from; adopted changes do not go back to the other device.
    public enum ChangeOrigin: Sendable { case local, remote }

    public init(settings: SettingsStore, signals: SignalEngine = SignalEngine()) {
        self.settings = settings
        self.signals = signals
    }

    public var showsTraining: Bool { run != nil || summary != nil }

    /// Reports every change to the run.
    public func observe(_ b: @escaping (Timekeeper?, ChangeOrigin) -> Void) {
        observers.append(b)
    }

    public func start(_ template: Template, at time: Date = .now) {
        summary = nil
        mirrored = false
        apply(Timekeeper(template: template, start: time), .local)
    }

    public func perform(_ command: Command, at time: Date = .now) {
        guard var t = run else { return }
        switch command {
        case .pause: t.pause(time)
        case .resume: t.resume(time)
        case .skip: t.skip(time)
        case .end:
            end(at: time)
            return
        }
        apply(t, .local)
    }

    /// By hand or because the plan is done; the summary screen follows.
    public func end(at time: Date = .now) {
        guard var t = run else { return }
        summary = t.summary(time)
        t.end()
        apply(nil, .local)
    }

    /// Adopts the state of the other device. An ended run brings its summary along.
    public func adopt(_ new: Timekeeper?, summary e: WorkoutSummary? = nil) {
        guard new != run || e != nil else { return }
        if let e { summary = e }
        if new != nil { summary = nil }
        // A new run from the other device belongs to the other device; a command for our own run
        // (pause on the watch) does not change that.
        if let new, new.start != run?.start { mirrored = true }
        apply(new, .remote)
    }

    /// Adds calories and heart rate as soon as the watch delivers them.
    public func attach(calories: Int?, heartRate: Int?) {
        // Read first, then write: `summary?.x = y ?? summary?.x` accesses twice.
        guard var e = summary else { return }
        e.calories = calories ?? e.calories
        e.heartRate = heartRate ?? e.heartRate
        summary = e
    }

    public func close() {
        summary = nil
    }

    /// Settings changed: reschedule the signals immediately.
    public func settingsChanged() {
        if let run { signals.follow(run, settings: settings.values, hapticsOnly: mirrored) }
    }

    private func apply(_ t: Timekeeper?, _ origin: ChangeOrigin) {
        run = t
        if t == nil { mirrored = false }
        signals.follow(t, settings: settings.values, hapticsOnly: mirrored)
        for b in observers { b(t, origin) }
    }
}
