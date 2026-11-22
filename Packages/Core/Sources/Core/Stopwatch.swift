import Foundation

/// Stopwatch with lap times; it also powers laps mode (a round is a lap time).
///
/// Like the timekeeper it stores only points in time and computes the display. That way it keeps
/// running across app switches, locking and even an app restart.
public struct Stopwatch: Codable, Sendable, Hashable {
    public private(set) var start: Date?
    public private(set) var pausedSince: Date?
    public private(set) var pausedTotal: TimeInterval = 0
    /// Total time at the end of each lap.
    public private(set) var marks: [TimeInterval] = []

    private enum CodingKeys: String, CodingKey {
        case start
        case pausedSince = "angehaltenSeit"
        case pausedTotal = "angehalten"
        case marks = "marken"
    }

    public init() {}

    public var hasStarted: Bool { start != nil }
    public var isRunning: Bool { start != nil && pausedSince == nil }

    public func elapsed(_ time: Date) -> TimeInterval {
        guard let start else { return 0 }
        let to = pausedSince.map { min($0, time) } ?? time
        return max(0, to.timeIntervalSince(start) - pausedTotal)
    }

    public mutating func start(_ time: Date) {
        if start == nil {
            start = time
        } else {
            resume(time)
        }
    }

    public mutating func pause(_ time: Date) {
        guard isRunning else { return }
        pausedSince = time
    }

    public mutating func resume(_ time: Date) {
        guard let since = pausedSince else { return }
        pausedTotal += max(0, time.timeIntervalSince(since))
        pausedSince = nil
    }

    /// Closes the current lap; starts the stopwatch if it is still stopped.
    public mutating func lap(_ time: Date) {
        guard isRunning else {
            if !hasStarted { start(time) }
            return
        }
        marks.append(elapsed(time))
    }

    public mutating func reset() {
        self = Stopwatch()
    }

    /// Duration of every completed lap, first lap first.
    public var lapTimes: [TimeInterval] {
        zip(marks, [0] + marks).map { $0 - $1 }
    }

    /// Index of the fastest lap, from two laps on.
    public var best: Int? {
        let z = lapTimes
        guard z.count >= 2 else { return nil }
        return z.indices.min { z[$0] < z[$1] }
    }

    /// The current lap, 1-based.
    public var currentLap: Int { marks.count + 1 }

    public func currentLapTime(_ time: Date) -> TimeInterval {
        elapsed(time) - (marks.last ?? 0)
    }
}
