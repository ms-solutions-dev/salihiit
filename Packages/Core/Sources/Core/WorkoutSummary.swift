import Foundation

/// What the summary screen shows. Calories and heart rate come from the watch, otherwise `nil`.
public struct WorkoutSummary: Codable, Sendable, Hashable {
    public var template: String
    /// Actual workout time without paused time, in seconds.
    public var duration: Int
    /// Completed work phases.
    public var rounds: Int
    public var calories: Int?
    public var heartRate: Int?

    private enum CodingKeys: String, CodingKey {
        case template = "vorlage"
        case duration = "dauer"
        case rounds = "runden"
        case calories = "kalorien"
        case heartRate = "puls"
    }

    public init(template: String, duration: Int, rounds: Int, calories: Int? = nil, heartRate: Int? = nil) {
        self.template = template
        self.duration = duration
        self.rounds = rounds
        self.calories = calories
        self.heartRate = heartRate
    }
}

extension Timekeeper {
    /// The summary at time `time`. Paused time does not count as time, skipped work phases do
    /// not count as rounds.
    public func summary(_ time: Date) -> WorkoutSummary {
        let end = pausedSince.map { min($0, time) } ?? time
        let actual = max(0, end.timeIntervalSince(start) - pausedTotal)
        let t = min(elapsed(time), Double(plan.total))
        let reached = plan.phases.filter { $0.kind == .active && Double($0.end) <= t }.count
        return WorkoutSummary(
            template: template.name, duration: Int(actual.rounded()), rounds: max(0, reached - skippedActive))
    }
}
