import Foundation
import Testing

@testable import Core

@Suite struct StopwatchTests {
    let t0 = Date(timeIntervalSinceReferenceDate: 4_000_000)
    func at(_ s: Double) -> Date { t0.addingTimeInterval(s) }

    @Test func lapsAndBest() {
        var u = Stopwatch()
        u.lap(at(0))  // first tap starts
        #expect(u.isRunning && u.marks.isEmpty)
        u.lap(at(90))
        u.lap(at(164))
        u.lap(at(243))
        #expect(u.lapTimes == [90, 74, 79])
        #expect(u.best == 1)
        #expect(u.currentLap == 4)
        #expect(u.currentLapTime(at(250)) == 7)
    }

    @Test func pausingDoesNotCountTime() {
        var u = Stopwatch()
        u.start(at(0))
        u.pause(at(10))
        #expect(u.elapsed(at(500)) == 10)
        u.lap(at(20))  // paused: no lap
        #expect(u.marks.isEmpty)
        u.start(at(30))  // start on a paused stopwatch means resume
        #expect(u.elapsed(at(35)) == 15)
        u.reset()
        #expect(!u.hasStarted && u.elapsed(at(40)) == 0)
    }
}
