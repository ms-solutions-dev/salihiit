import Core
import Foundation
import Storage

/// A due signal with its date.
public struct DueSignal: Sendable, Hashable {
    public let event: Event
    public let time: Date
    /// Identifier for the notification that carries the same signal as a safety net.
    public var identifier: String { "signal-\(event.time)" }
}

/// Which signals belong to a run. Pure computation so it stays testable on a Mac.
public enum SignalSchedule {
    /// The next signal from `now`; `nil` if paused or finished.
    public static func next(
        _ run: Timekeeper, from now: Date, settings: Settings
    ) -> DueSignal? {
        upcoming(run, from: now, settings: settings, atMost: 1).first
    }

    /// The next signals from `now` as dates.
    ///
    /// Computes in windows of 10 minutes instead of over the whole plan: a plan with 99 × 99 rounds
    /// has 20,000 phases, and usually only the next signal is needed.
    /// - Parameter phasesOnly: only phase start and end, for the notifications as a safety net.
    public static func upcoming(
        _ run: Timekeeper, from now: Date, settings: Settings, atMost: Int,
        phasesOnly: Bool = false
    ) -> [DueSignal] {
        guard run.isRunning else { return [] }
        // Events sit on full seconds; what is due within this tenth of a second still counts.
        var from = Int((run.elapsed(now) - 0.05).rounded(.up))
        var list: [DueSignal] = []
        while list.count < atMost, from <= run.plan.total {
            let to = from + 600
            for e in run.plan.events(from: from, to: to)
            where wanted(e, settings: settings, phasesOnly: phasesOnly) {
                list.append(DueSignal(event: e, time: run.date(for: Double(e.time))))
                if list.count == atMost { break }
            }
            from = to
        }
        return list
    }

    static func wanted(_ e: Event, settings: Settings, phasesOnly: Bool) -> Bool {
        switch e.kind {
        case .phaseStart, .finished: true
        case .countdown(let n): !phasesOnly && n <= settings.countdownFrom
        // Halfway only spoken; a sound in the middle of an exercise would sound like a phase change.
        case .halfway: !phasesOnly && settings.voice
        }
    }
}
