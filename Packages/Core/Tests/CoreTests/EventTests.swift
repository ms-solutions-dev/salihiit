import Foundation
import Testing

@testable import Core

@Suite struct EventTests {
    @Test func countdownStartAndFinish() {
        let plan = PhasePlan(Template(name: "x", preparation: 5, active: 20, rest: 10, rounds: 2))
        let e = plan.events(from: 0, to: 1000)
        let times = e.map(\.time)
        #expect(times == times.sorted())
        // Preparation: start 0, countdown 2/3/4; work from 5 with halfway at 15.
        #expect(e.contains(Event(time: 2, kind: .countdown(3))))
        #expect(e.contains(Event(time: 4, kind: .countdown(1))))
        #expect(e.contains(Event(time: 15, kind: .halfway)))
        #expect(e.last == Event(time: 55, kind: .finished))
        #expect(e.filter { if case .phaseStart = $0.kind { true } else { false } }.count == 4)
    }

    @Test func shortPhasesWithoutCountdown() {
        let plan = PhasePlan(Template(name: "x", preparation: 3, active: 10, rest: 0, rounds: 1))
        let countdowns = plan.events(from: 0, to: 100).filter {
            if case .countdown = $0.kind { true } else { false }
        }
        // Preparation of 3 s: only "2" and "1"; work of 10 s: 5 to 1.
        #expect(countdowns.map(\.time) == [1, 2, 8, 9, 10, 11, 12])
    }

    @Test func windowCutsCleanly() {
        let plan = PhasePlan(Template.samples[1])
        let all = plan.events(from: 0, to: 10_000)
        let parts = plan.events(from: 0, to: 100) + plan.events(from: 100, to: 10_000)
        #expect(all == parts)
    }
}

@Test func timeFormat() {
    #expect(TimeFormat.short(17) == "0:17")
    #expect(TimeFormat.short(590) == "9:50")
    #expect(TimeFormat.short(605) == "10:05")
    #expect(TimeFormat.short(3725) == "1:02:05")
    let z = TimeFormat.tenths(207.46, locale: Locale(identifier: "de_DE"))
    #expect(z.main == "3:27" && z.tenths == ",4")
}
