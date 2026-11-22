import Foundation
import Testing

@testable import Core

@Suite struct TimekeeperTests {
    let start = Date(timeIntervalSinceReferenceDate: 1_000_000)
    var circuits: Template { Template.samples[0] }

    func at(_ s: Double) -> Date { start.addingTimeInterval(s) }

    @Test func displayDerivedFromStartTime() {
        let t = Timekeeper(template: circuits, start: start)
        let z = t.state(at(17.2))
        // 5 s preparation, then 12.2 s into the first work phase.
        #expect(z.phase?.kind == .active)
        #expect(z.remainingSeconds == 18)
        #expect(z.next?.kind == .rest)
        #expect(z.totalRemainingSeconds == 573)
    }

    @Test func timeJumpAfterSleep() {
        // The device slept for 3 min: the display jumps straight to the right place.
        let t = Timekeeper(template: circuits, start: start)
        let z = t.state(at(205))
        // 5 s preparation + 165 s first circuit + 30 s circuit rest = 200 → 5 s into circuit 2.
        #expect(z.phase?.kind == .active)
        #expect(z.remainingSeconds == 25)
        #expect(z.phase?.circuit == 2)
        #expect(z.phase?.round == 1)
    }

    @Test func pausingAcrossPhaseBoundaries() {
        var t = Timekeeper(template: circuits, start: start)
        t.pause(at(33))  // 2 s before the end of the first work phase
        #expect(t.state(at(100)).remainingSeconds == 2)
        #expect(t.state(at(100)).phase?.kind == .active)
        #expect(t.phaseEnd(at(100)) == nil)
        t.resume(at(100))
        #expect(t.state(at(101)).remainingSeconds == 1)
        #expect(t.state(at(103)).phase?.kind == .rest)
        #expect(t.phaseEnd(at(101)) == at(102))
    }

    @Test func skipInLastSecond() {
        var t = Timekeeper(template: circuits, start: start)
        t.skip(at(34.9))
        let z = t.state(at(34.9))
        #expect(z.phase?.kind == .rest)
        #expect(z.remainingSeconds == 15)
        // Once more: the next work phase, round 2.
        t.skip(at(34.9))
        #expect(t.state(at(34.9)).phase?.round == 2)
    }

    @Test func skipWhilePaused() {
        var t = Timekeeper(template: circuits, start: start)
        t.pause(at(10))
        t.skip(at(20))
        #expect(t.state(at(60)).phase?.kind == .rest)
        #expect(t.state(at(60)).remainingSeconds == 15)
    }

    @Test func skippingLastPhaseEnds() {
        var t = Timekeeper(template: circuits, start: start)
        t.skip(at(Double(t.plan.total) - 10))
        #expect(t.state(at(Double(t.plan.total) - 10)).finished)
    }

    @Test func finishedAndEnded() {
        var t = Timekeeper(template: circuits, start: start)
        #expect(t.state(at(589.9)).finished == false)
        #expect(t.state(at(590)).finished)
        t.end()
        #expect(t.state(at(10)).finished)
        #expect(t.isRunning == false)
    }

    @Test func dateForTrainingTime() {
        var t = Timekeeper(template: circuits, start: start)
        t.pause(at(10))
        t.resume(at(40))
        #expect(t.date(for: 35) == at(65))
    }

    @Test func survivesEncoding() throws {
        var t = Timekeeper(template: circuits, start: start)
        t.pause(at(12))
        let back = try JSONDecoder().decode(Timekeeper.self, from: JSONEncoder().encode(t))
        #expect(back == t)
    }
}

@Suite struct WorkoutSummaryTests {
    let start = Date(timeIntervalSinceReferenceDate: 2_000_000)
    func at(_ s: Double) -> Date { start.addingTimeInterval(s) }

    @Test func fullRoundWithoutPause() {
        let t = Timekeeper(template: Template.samples[0], start: start)
        let e = t.summary(at(590))
        #expect(e.duration == 590 && e.rounds == 12 && e.template == "Zirkel")
    }

    @Test func pausingDoesNotCountSkippingIsNoRound() {
        var t = Timekeeper(template: Template.samples[0], start: start)
        t.pause(at(10))
        t.resume(at(70))  // paused for 60 s
        t.skip(at(75))  // in the middle of work phase 1
        let e = t.summary(at(100))
        #expect(e.duration == 40)
        // At 100 s of wall time: 40 s actual + 25 s skip = 65 s workout time → work 1 skipped, work 2 running.
        #expect(e.rounds == 0)
    }
}

@Suite struct IslandStateTests {
    let start = Date(timeIntervalSinceReferenceDate: 5_000_000)
    func at(_ s: Double) -> Date { start.addingTimeInterval(s) }

    @Test func runningPhase() {
        let run = Timekeeper(template: Template.samples[0], start: start)
        let s = IslandState(run, time: at(17.5))
        #expect(s.kind == .active && s.round == 1 && s.circuitTotal == 3)
        #expect(s.phaseStart == at(5) && s.phaseEnd == at(35))
        #expect(s.nextKind == .rest && s.nextDuration == 15)
        #expect(!s.isPaused)
    }

    @Test func pausedHasNoPhaseEnd() {
        var run = Timekeeper(template: Template.samples[0], start: start)
        run.pause(at(20))
        let s = IslandState(run, time: at(60))
        #expect(s.isPaused && s.remainingSeconds == 15 && s.phaseEnd == nil)
    }
}

/// Display and sound must show the same number: the countdown "5" falls on the instant the
/// display jumps to 0:05, and at every tick of the display (aligned to `date(for: 0)`) the
/// matching number is shown.
@Test func countdownMatchesDisplay() {
    let start = Date(timeIntervalSinceReferenceDate: 8_000_000)
    var run = Timekeeper(
        template: Template(name: "x", preparation: 5, active: 20, rest: 10, rounds: 2), start: start)
    run.pause(start.addingTimeInterval(7.37))
    run.resume(start.addingTimeInterval(9.81))
    for e in run.plan.events(from: 0, to: 1000) {
        guard case .countdown(let n) = e.kind else { continue }
        let time = run.date(for: Double(e.time))
        #expect(run.state(time).remainingSeconds == n)
        // 10 ms earlier the number above is still shown.
        #expect(run.state(time.addingTimeInterval(-0.01)).remainingSeconds == n + 1)
        // The display tick hits the full second exactly: the distance to the anchor is a multiple of 0.1 s.
        let gap = time.timeIntervalSince(run.date(for: 0)) * 10
        #expect(abs(gap - gap.rounded()) < 1e-6)
    }
}
