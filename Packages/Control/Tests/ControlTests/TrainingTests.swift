import Core
import Foundation
import Storage
import Testing

@testable import Control

@MainActor @Suite struct TrainingTests {
    let start = Date(timeIntervalSinceReferenceDate: 6_000_000)
    func at(_ s: Double) -> Date { start.addingTimeInterval(s) }

    func new() -> Training {
        Training(
            settings: SettingsStore(storage: UserDefaults(suiteName: "t-\(UUID().uuidString)")!))
    }

    @Test func startPauseEnd() {
        let t = new()
        var notifications: [Training.ChangeOrigin] = []
        t.observe { _, h in notifications.append(h) }
        t.start(Template.samples[1], at: start)
        t.perform(.pause, at: at(10))
        #expect(t.run?.isRunning == false)
        t.perform(.resume, at: at(20))
        t.perform(.end, at: at(30))
        #expect(t.run == nil)
        #expect(t.summary?.duration == 20)
        #expect(t.showsTraining)
        t.close()
        #expect(!t.showsTraining)
        #expect(notifications == [.local, .local, .local, .local])
    }

    @Test func adoptReportsOrigin() {
        let t = new()
        var last: Training.ChangeOrigin?
        t.observe { _, h in last = h }
        t.adopt(Timekeeper(template: Template.samples[0], start: start))
        #expect(last == .remote && t.run != nil)
        // Same state again: no report, no loop between the devices.
        last = nil
        t.adopt(t.run)
        #expect(last == nil)
        t.adopt(nil, summary: WorkoutSummary(template: "Zirkel", duration: 100, rounds: 3))
        #expect(t.summary?.rounds == 3 && t.run == nil)
    }

    @Test func attachFromWatch() {
        let t = new()
        t.start(Template.samples[1], at: start)
        t.end(at: at(60))
        t.attach(calories: 42, heartRate: nil)
        t.attach(calories: nil, heartRate: 138)
        #expect(t.summary?.calories == 42 && t.summary?.heartRate == 138)
    }

    @Test func mirroredRunStaysSilent() {
        let t = new()
        let foreign = Timekeeper(template: Template.samples[0], start: start)
        t.adopt(foreign)
        #expect(t.mirrored)
        // Pause on the mirroring device: the run still belongs to the other device.
        t.perform(.pause, at: at(10))
        #expect(t.mirrored)
        // State from the other device for the same run (resume): stays mirrored.
        var resume = t.run!
        resume.resume(at(20))
        t.adopt(resume)
        #expect(t.mirrored)
        // Started ourselves: sounds here.
        t.start(Template.samples[1], at: at(100))
        #expect(!t.mirrored)
        // Ended: reset.
        t.adopt(foreign)
        t.end(at: at(120))
        #expect(!t.mirrored)
    }
}
