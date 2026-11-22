import Foundation

/// An interval workout as the editor creates it. All times in seconds.
///
/// A round is work + rest, a circuit is `rounds` rounds. After the last round of a circuit the rest
/// between circuits replaces the rest, after the last circuit comes the cooldown.
public struct Template: Codable, Sendable, Hashable, Identifiable {
    public var id: UUID
    public var name: String
    public var preparation: Int
    public var active: Int
    public var rest: Int
    public var rounds: Int
    public var circuits: Int
    public var circuitRest: Int
    public var cooldown: Int
    /// Exercise names per circuit and round, optional. Empty names mean "none".
    public var exercises: [[String]]
    /// If true, the first row of `exercises` applies to every circuit.
    public var sameExercises: Bool

    private enum CodingKeys: String, CodingKey {
        case id, name
        case preparation = "vorbereitung"
        case active = "aktiv"
        case rest = "pause"
        case rounds = "runden"
        case circuits = "zirkel"
        case circuitRest = "zirkelpause"
        case cooldown = "auslaufen"
        case exercises = "uebungen"
        case sameExercises = "gleicheUebungen"
    }

    public init(
        id: UUID = UUID(), name: String, preparation: Int = 5, active: Int, rest: Int, rounds: Int,
        circuits: Int = 1, circuitRest: Int = 0, cooldown: Int = 0, exercises: [[String]] = [],
        sameExercises: Bool = true
    ) {
        self.id = id
        self.name = name
        self.preparation = preparation
        self.active = active
        self.rest = rest
        self.rounds = rounds
        self.circuits = circuits
        self.circuitRest = circuitRest
        self.cooldown = cooldown
        self.exercises = exercises
        self.sameExercises = sameExercises
    }

    /// The exercise name for a round (both 1-based), `nil` without a name.
    public func exercise(circuit z: Int, round r: Int) -> String? {
        let row = sameExercises ? 0 : z - 1
        guard exercises.indices.contains(row), exercises[row].indices.contains(r - 1) else { return nil }
        let name = exercises[row][r - 1].trimmingCharacters(in: .whitespaces)
        return name.isEmpty ? nil : name
    }

    /// Keeps all values within sensible limits before a plan is built from them.
    public var clamped: Template {
        var v = self
        v.preparation = min(max(v.preparation, 0), Limits.duration)
        v.active = min(max(v.active, 1), Limits.duration)
        v.rest = min(max(v.rest, 0), Limits.duration)
        v.rounds = min(max(v.rounds, 1), Limits.count)
        v.circuits = min(max(v.circuits, 1), Limits.count)
        v.circuitRest = min(max(v.circuitRest, 0), Limits.duration)
        v.cooldown = min(max(v.cooldown, 0), Limits.duration)
        return v
    }

    public enum Limits {
        /// 99:59 per phase.
        public static let duration = 5999
        public static let count = 99
    }
}

extension Template {
    /// What the list contains on first launch.
    public static let samples: [Template] = [
        Template(
            name: "Zirkel", active: 30, rest: 15, rounds: 4, circuits: 3, circuitRest: 30, cooldown: 30),
        Template(name: "Tabata", active: 20, rest: 10, rounds: 8),
        Template(name: "HIIT 40/20", active: 40, rest: 20, rounds: 10),
        Template(name: "Plank", active: 60, rest: 30, rounds: 4),
    ]
}
