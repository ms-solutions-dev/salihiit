import Foundation

/// The run of a workout. It holds only points in time, never a counter: the display is computed
/// from start time and plan at any moment, so it is correct again immediately after locking,
/// switching apps or watch sleep.
public struct Timekeeper: Codable, Sendable, Hashable {
    public let plan: PhasePlan
    public let template: Template
    public private(set) var start: Date
    /// Set while paused.
    public private(set) var pausedSince: Date?
    /// Sum of all completed pauses.
    public private(set) var pausedTotal: TimeInterval = 0
    /// Skipped seconds; moves the workout time forward.
    public private(set) var skipOffset: TimeInterval = 0
    public private(set) var ended = false
    /// Skipped work phases; they do not count as rounds in the summary.
    public private(set) var skippedActive = 0

    private enum CodingKeys: String, CodingKey {
        case plan
        case template = "vorlage"
        case start
        case pausedSince = "angehaltenSeit"
        case pausedTotal = "angehalten"
        case skipOffset = "sprung"
        case ended = "beendet"
        case skippedActive = "uebersprungeneAktiv"
    }

    public init(template: Template, start: Date) {
        self.template = template
        self.plan = PhasePlan(template)
        self.start = start
    }

    /// Workout time in seconds at the point in time `time`.
    public func elapsed(_ time: Date) -> Double {
        let to = pausedSince.map { min($0, time) } ?? time
        return max(0, to.timeIntervalSince(start) - pausedTotal + skipOffset)
    }

    public var isRunning: Bool { pausedSince == nil && !ended }

    public mutating func pause(_ time: Date) {
        guard isRunning else { return }
        pausedSince = time
    }

    public mutating func resume(_ time: Date) {
        guard let since = pausedSince, !ended else { return }
        pausedTotal += max(0, time.timeIntervalSince(since))
        pausedSince = nil
    }

    /// Jumps to the start of the next phase; in the last phase to the end.
    public mutating func skip(_ time: Date) {
        guard !ended else { return }
        let t = elapsed(time)
        guard let i = plan.index(at: t) else { return }
        if plan.phases[i].kind == .active { skippedActive += 1 }
        skipOffset += Double(plan.phases[i].end) - t
    }

    public mutating func end() {
        ended = true
    }

    /// What the display shows at the point in time `time`.
    public func state(_ time: Date) -> DisplayState {
        let t = elapsed(time)
        guard !ended, let i = plan.index(at: t) else {
            return DisplayState(
                phase: nil, index: nil, remaining: 0, progress: 1, totalRemaining: 0, next: nil,
                finished: true)
        }
        let p = plan.phases[i]
        let remaining = Double(p.end) - t
        return DisplayState(
            phase: p, index: i, remaining: remaining, progress: 1 - remaining / Double(p.duration),
            totalRemaining: Double(plan.total) - t, next: plan.after(i), finished: false)
    }

    /// When the running phase ends, as a date; `nil` if paused or finished.
    /// For `Text(timerInterval:)` in the Live Activity and on the watch.
    public func phaseEnd(_ time: Date) -> Date? {
        guard isRunning else { return nil }
        let z = state(time)
        guard !z.finished else { return nil }
        return time.addingTimeInterval(z.remaining)
    }

    /// Converts a workout time into a date, assuming nothing is paused any more.
    public func date(for trainingTime: Double) -> Date {
        start.addingTimeInterval(trainingTime + pausedTotal - skipOffset)
    }
}

/// The display at a point in time.
public struct DisplayState: Sendable, Hashable {
    public let phase: Phase?
    public let index: Int?
    /// Seconds until the phase ends.
    public let remaining: Double
    /// 0 at the start of the phase, 1 at the end.
    public let progress: Double
    public let totalRemaining: Double
    public let next: Phase?
    public let finished: Bool

    /// The displayed number of seconds: rounded up, so "0:01" is the last full second
    /// and "0:00" never stays on screen.
    public var remainingSeconds: Int { Int(remaining.rounded(.up)) }
    public var totalRemainingSeconds: Int { Int(totalRemaining.rounded(.up)) }
}
