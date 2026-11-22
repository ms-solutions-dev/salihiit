import Core
import Foundation
import Storage
import Testing

@testable import Signals

@Suite struct SignalScheduleTests {
    let start = Date(timeIntervalSinceReferenceDate: 3_000_000)
    let template = Template(name: "x", preparation: 5, active: 20, rest: 10, rounds: 2)
    func at(_ s: Double) -> Date { start.addingTimeInterval(s) }

    @Test func nextSignalWithCountdown() {
        let run = Timekeeper(template: template, start: start)
        let f = SignalSchedule.next(run, from: at(0.5), settings: .standard)
        #expect(f?.event == Event(time: 2, kind: .countdown(3)))
        #expect(f?.time == at(2))
    }

    @Test func withoutCountdownAndVoice() {
        var e = Settings.standard
        e.countdownFrom = 0
        let run = Timekeeper(template: template, start: start)
        let list = SignalSchedule.upcoming(run, from: at(0), settings: e, atMost: 100)
        // Start per phase (4) + finished; halfway only with voice.
        #expect(list.count == 5)
        e.voice = true
        #expect(SignalSchedule.upcoming(run, from: at(0), settings: e, atMost: 100).count == 7)
    }

    @Test func exactlyDueStillCounts() {
        let run = Timekeeper(template: template, start: start)
        // 30 ms after the start of the work phase: the start signal is still due.
        let f = SignalSchedule.next(run, from: at(5.03), settings: .standard)
        if case .phaseStart(let p) = f?.event.kind {
            #expect(p.kind == .active)
        } else {
            Issue.record("no start")
        }
    }

    @Test func pausedMeansNoSignals() {
        var run = Timekeeper(template: template, start: start)
        run.pause(at(3))
        #expect(SignalSchedule.next(run, from: at(4), settings: .standard) == nil)
    }

    @Test func dateAccountsForPauseAndSkip() {
        var run = Timekeeper(template: template, start: start)
        run.pause(at(1))
        run.resume(at(11))
        let f = SignalSchedule.next(run, from: at(11), settings: .standard)
        #expect(f?.time == at(12))  // countdown "3" at workout time 2 = 1 + 10 s pause + 1
    }

    @Test func netPhasesOnlyAtMost() {
        let large = Template(name: "g", active: 5, rest: 5, rounds: 99, circuits: 99)
        let run = Timekeeper(template: large, start: start)
        let list = SignalSchedule.upcoming(
            run, from: at(0), settings: .standard, atMost: 60, phasesOnly: true)
        #expect(list.count == 60)
        #expect(list.allSatisfy { if case .phaseStart = $0.event.kind { true } else { false } })
    }

    @Test func countdownFromFiveWithCoach() {
        var e = Settings.standard
        e.countdownFrom = 5
        e.coach = "daniel"
        let run = Timekeeper(template: template, start: start)
        let f = SignalSchedule.next(run, from: at(5.5), settings: e)
        #expect(f?.event == Event(time: 20, kind: .countdown(5)))
        let a = Announcement.make(f!.event, settings: e)
        #expect(a.file(.whistle) == "Stimmen/daniel/5" && a.text == nil)
        // The default stays 3: the "5" is dropped.
        #expect(SignalSchedule.next(run, from: at(5.5), settings: .standard)?.event.time == 22)
    }

    @Test func oldSettingsWithoutCountdown() throws {
        let old = try JSONDecoder().decode(Settings.self, from: Data(#"{"countdown":false}"#.utf8))
        #expect(old.countdownFrom == 0)
        let new = try JSONDecoder().decode(Settings.self, from: JSONEncoder().encode(Settings()))
        #expect(new.countdownFrom == 3 && new.coach == nil)
    }

    @Test func announcementPerEvent() {
        var e = Settings.standard
        e.voice = true
        let p = Phase(kind: .active, start: 5, duration: 20, round: 1, circuit: 1, exercise: "Plank")
        let a = Announcement.make(Event(time: 5, kind: .phaseStart(p)), settings: e)
        #expect(a.sound == .long && a.text?.hasSuffix("Plank") == true && a.haptic == .phase)
        #expect(a.file(.bell) == "Toene/glocke-lang")
        let c = Announcement.make(Event(time: 2, kind: .countdown(3)), settings: .standard)
        #expect(c.text == nil && c.sound == .short)
    }
}
