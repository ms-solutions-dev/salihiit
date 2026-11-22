import Foundation

/// A phase in the plan. Times in seconds from the start of the workout.
public struct Phase: Codable, Sendable, Hashable {
    public var kind: PhaseKind
    public var start: Int
    public var duration: Int
    /// 1-based; 1 for the preparation, the last round for the cooldown.
    public var round: Int
    public var circuit: Int
    public var exercise: String?

    public var end: Int { start + duration }

    public init(
        kind: PhaseKind, start: Int, duration: Int, round: Int, circuit: Int, exercise: String? = nil
    ) {
        self.kind = kind
        self.start = start
        self.duration = duration
        self.round = round
        self.circuit = circuit
        self.exercise = exercise
    }

    private enum CodingKeys: String, CodingKey {
        case kind = "art"
        case start = "beginn"
        case duration = "dauer"
        case round = "runde"
        case circuit = "zirkel"
        case exercise = "uebung"
    }
}

/// The flat list of all phases of a template. Phone, watch and island compute the same display
/// from the same plan and the same start time.
public struct PhasePlan: Codable, Sendable, Hashable {
    public let phases: [Phase]
    public let rounds: Int
    public let circuits: Int

    private enum CodingKeys: String, CodingKey {
        case phases = "phasen"
        case rounds = "runden"
        case circuits = "zirkel"
    }

    public var total: Int { phases.last?.end ?? 0 }

    public init(_ template: Template) {
        let v = template.clamped
        var list: [Phase] = []
        var t = 0
        func add(_ kind: PhaseKind, _ duration: Int, round: Int, circuit: Int, exercise: String? = nil) {
            // Phases of 0 s are dropped, otherwise their color would flash for one frame.
            guard duration > 0 else { return }
            list.append(
                Phase(
                    kind: kind, start: t, duration: duration, round: round, circuit: circuit,
                    exercise: exercise))
            t += duration
        }
        add(.preparation, v.preparation, round: 1, circuit: 1, exercise: v.exercise(circuit: 1, round: 1))
        for z in 1...v.circuits {
            for r in 1...v.rounds {
                add(.active, v.active, round: r, circuit: z, exercise: v.exercise(circuit: z, round: r))
                if r < v.rounds {
                    add(.rest, v.rest, round: r, circuit: z)
                } else if z < v.circuits {
                    add(.circuitRest, v.circuitRest, round: r, circuit: z)
                }
            }
        }
        add(.cooldown, v.cooldown, round: v.rounds, circuit: v.circuits)
        phases = list
        rounds = v.rounds
        circuits = v.circuits
    }

    /// Index of the phase running at second `t`; `nil` before the start and after the end.
    public func index(at t: Double) -> Int? {
        guard t >= 0, t < Double(total) else { return nil }
        // Binary search: plans with 99 × 99 rounds have almost 20,000 phases.
        var bottom = 0
        var top = phases.count - 1
        while bottom < top {
            let mid = (bottom + top + 1) / 2
            if Double(phases[mid].start) <= t { bottom = mid } else { top = mid - 1 }
        }
        return bottom
    }

    /// The phase after `index`, if there is one.
    public func after(_ index: Int) -> Phase? {
        phases.indices.contains(index + 1) ? phases[index + 1] : nil
    }
}
