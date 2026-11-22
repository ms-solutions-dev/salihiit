import Core
import Foundation
import Storage
import Testing

@testable import Connectivity

@Test func messagesSurviveTheWire() throws {
    var run = Timekeeper(
        template: Template.samples[0], start: Date(timeIntervalSinceReferenceDate: 7_000_000))
    run.pause(Date(timeIntervalSinceReferenceDate: 7_000_030))
    var e = Settings()
    e.voice = true
    let all: [Message] = [
        .templates(Template.samples), .settings(e), .run(run, summary: nil),
        .run(nil, summary: WorkoutSummary(template: "Zirkel", duration: 590, rounds: 12)),
        .values(calories: 88, heartRate: 141),
    ]
    for n in all {
        #expect(Message.decoded(try n.encoded()) == n)
    }
}

@Test func contextKeepsTemplatesAndSettingsSeparate() {
    #expect(WatchLink.contextKey(.templates([])) == "vorlagen")
    #expect(WatchLink.contextKey(.settings(Settings())) == "einstellungen")
}

@Test func foreignContentIsIgnored() {
    #expect(Message.decoded(["x": 1]) == nil)
    #expect(Message.decoded(["n": Data("broken".utf8)]) == nil)
}
