import Core
import Foundation
import Observation

/// Laps mode and stopwatch survive an app restart.
@MainActor @Observable public final class ClockStore {
    public var laps: Stopwatch { didSet { write(laps, "uhr.runden") } }
    public var stopwatch: Stopwatch { didSet { write(stopwatch, "uhr.stoppuhr") } }

    @ObservationIgnored private let storage: UserDefaults

    public init(storage: UserDefaults? = nil) {
        let s = storage ?? UserDefaults(suiteName: Identifiers.appGroup) ?? .standard
        self.storage = s
        laps = Self.load(s, "uhr.runden")
        stopwatch = Self.load(s, "uhr.stoppuhr")
    }

    private static func load(_ s: UserDefaults, _ key: String) -> Stopwatch {
        s.data(forKey: key).flatMap { try? JSONDecoder().decode(Stopwatch.self, from: $0) }
            ?? Stopwatch()
    }

    private func write(_ clock: Stopwatch, _ key: String) {
        storage.set(try? JSONEncoder().encode(clock), forKey: key)
    }
}
