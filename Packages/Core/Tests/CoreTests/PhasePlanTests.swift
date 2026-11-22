import Foundation
import Testing

@testable import Core

@Suite struct PhasePlanTests {
    let circuits = Template.samples[0]

    @Test func totalTimesOfSamples() {
        // Circuit of 9:50; Tabata and HIIT without a rest after the last round.
        let times = Template.samples.map { TimeFormat.short(PhasePlan($0).total) }
        #expect(times == ["9:50", "3:55", "9:45", "5:35"])
    }

    @Test func orderWithinCircuit() {
        let kinds = PhasePlan(circuits).phases.map(\.kind)
        #expect(kinds.first == .preparation)
        #expect(kinds.last == .cooldown)
        #expect(kinds.filter { $0 == .active }.count == 12)
        #expect(kinds.filter { $0 == .rest }.count == 9)
        #expect(kinds.filter { $0 == .circuitRest }.count == 2)
        // After the 4th work phase comes the circuit rest, not the normal rest.
        let fourth = PhasePlan(circuits).phases.firstIndex { $0.kind == .active && $0.round == 4 }!
        #expect(PhasePlan(circuits).phases[fourth + 1].kind == .circuitRest)
    }

    @Test func zeroLengthPhasesAreDropped() {
        let v = Template(name: "x", preparation: 0, active: 10, rest: 0, rounds: 3)
        let plan = PhasePlan(v)
        #expect(plan.phases.map(\.kind) == [.active, .active, .active])
        #expect(plan.total == 30)
    }

    @Test func indexFindsEverySecond() {
        let plan = PhasePlan(circuits)
        for t in stride(from: 0.0, to: Double(plan.total), by: 0.5) {
            let i = plan.index(at: t)!
            #expect(Double(plan.phases[i].start) <= t && t < Double(plan.phases[i].end))
        }
        #expect(plan.index(at: -1) == nil)
        #expect(plan.index(at: Double(plan.total)) == nil)
    }

    @Test func exerciseNames() {
        var v = circuits
        v.exercises = [["Push-ups", "Squats", "  ", "Plank"]]
        let active = PhasePlan(v).phases.filter { $0.kind == .active }
        #expect(active.prefix(4).map(\.exercise) == ["Push-ups", "Squats", nil, "Plank"])
        // Same in every circuit: the third circuit carries the names too.
        #expect(active[8].exercise == "Push-ups")
        // The preparation announces the first exercise.
        #expect(PhasePlan(v).phases[0].exercise == "Push-ups")

        v.sameExercises = false
        v.exercises = [["A"], ["B"]]
        let other = PhasePlan(v).phases.filter { $0.kind == .active && $0.round == 1 }
        #expect(other.map(\.exercise) == ["A", "B", nil])
    }

    @Test func limitsAreEnforced() {
        let v = Template(name: "x", active: 0, rest: -5, rounds: 500, circuits: 0)
        let b = v.clamped
        #expect(b.active == 1 && b.rest == 0 && b.rounds == 99 && b.circuits == 1)
    }
}
