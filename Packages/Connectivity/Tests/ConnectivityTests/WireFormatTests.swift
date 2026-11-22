import Core
import Foundation
import Storage
import Testing

@testable import Connectivity

/// Stored data and watch messages use the original (German) field names. This test pins the
/// exact JSON so renaming Swift properties can never break existing installs.
@Suite struct WireFormatTests {
    let start = Date(timeIntervalSinceReferenceDate: 7_000_000)

    var template: Template {
        Template(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!, name: "X", active: 30, rest: 15,
            rounds: 2, circuits: 2, circuitRest: 20, cooldown: 10, exercises: [["a", "b"]],
            sameExercises: false)
    }

    var run: Timekeeper {
        var t = Timekeeper(template: template, start: start)
        t.pause(start.addingTimeInterval(7))
        t.resume(start.addingTimeInterval(9))
        t.skip(start.addingTimeInterval(11))
        return t
    }

    var settings: Settings {
        var e = Settings()
        e.voice = true
        e.coach = "daniel"
        e.icon = .dark
        return e
    }

    var summary: WorkoutSummary {
        WorkoutSummary(template: "Z", duration: 5, rounds: 2, calories: 9, heartRate: 140)
    }

    func json<T: Encodable>(_ value: T) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return String(decoding: try encoder.encode(value), as: UTF8.self)
    }

    @Test func templateJSON() throws {
        #expect(
            try json(template)
                == #"{"aktiv":30,"auslaufen":10,"gleicheUebungen":false,"id":"00000000-0000-0000-0000-000000000001","name":"X","pause":15,"runden":2,"uebungen":[["a","b"]],"vorbereitung":5,"zirkel":2,"zirkelpause":20}"#
        )
    }

    @Test func timekeeperJSON() throws {
        #expect(
            try json(run)
                == #"{"angehalten":2,"beendet":false,"plan":{"phasen":[{"art":"vorbereitung","beginn":0,"dauer":5,"runde":1,"uebung":"a","zirkel":1},{"art":"aktiv","beginn":5,"dauer":30,"runde":1,"uebung":"a","zirkel":1},{"art":"pause","beginn":35,"dauer":15,"runde":1,"zirkel":1},{"art":"aktiv","beginn":50,"dauer":30,"runde":2,"uebung":"b","zirkel":1},{"art":"zirkelpause","beginn":80,"dauer":20,"runde":2,"zirkel":1},{"art":"aktiv","beginn":100,"dauer":30,"runde":1,"zirkel":2},{"art":"pause","beginn":130,"dauer":15,"runde":1,"zirkel":2},{"art":"aktiv","beginn":145,"dauer":30,"runde":2,"zirkel":2},{"art":"auslaufen","beginn":175,"dauer":10,"runde":2,"zirkel":2}],"runden":2,"zirkel":2},"sprung":26,"start":7000000,"uebersprungeneAktiv":1,"vorlage":{"aktiv":30,"auslaufen":10,"gleicheUebungen":false,"id":"00000000-0000-0000-0000-000000000001","name":"X","pause":15,"runden":2,"uebungen":[["a","b"]],"vorbereitung":5,"zirkel":2,"zirkelpause":20}}"#
        )
    }

    @Test func stopwatchJSON() throws {
        #expect(
            try json(stopwatch())
                == #"{"angehalten":0,"angehaltenSeit":7000004,"marken":[3],"start":7000000}"#)
    }

    @Test func settingsJSON() throws {
        #expect(
            try json(settings)
                == #"{"bildschirmAn":true,"coach":"daniel","countdownAb":3,"countdownLaenge":3,"health":true,"musikLeiser":true,"stimme":true,"symbol":"fit","tonsatz":"pfeife","vibration":true}"#
        )
    }

    @Test func summaryJSON() throws {
        #expect(try json(summary) == #"{"dauer":5,"kalorien":9,"puls":140,"runden":2,"vorlage":"Z"}"#)
    }

    @Test func islandStateJSON() throws {
        #expect(
            try json(IslandState(run, time: start.addingTimeInterval(12)))
                == #"{"art":"pause","fertig":false,"naechsteArt":"aktiv","naechsteDauer":30,"phasenBeginn":7000011,"phasenEnde":7000026,"restSekunden":14,"runde":1,"runden":2,"zirkel":1,"zirkelGesamt":2}"#
        )
    }

    @Test func commandsJSON() throws {
        #expect(
            try json([Command.pause, .resume, .skip, .end])
                == #"["anhalten","weiter","ueberspringen","beenden"]"#)
    }

    @Test func phaseKindsJSON() throws {
        #expect(
            try json(PhaseKind.allCases) == #"["vorbereitung","aktiv","pause","zirkelpause","auslaufen"]"#)
    }

    @Test func soundSetsJSON() throws {
        #expect(try json(SoundSet.allCases) == #"["pfeife","glocke","gong","digital","piep"]"#)
    }

    @Test func appIconsJSON() throws {
        #expect(try json(AppIcon.allCases) == #"["wortmarke","ring","stoppuhr","monogramm","puls","fit"]"#)
    }

    func stopwatch() -> Stopwatch {
        var s = Stopwatch()
        s.start(start)
        s.lap(start.addingTimeInterval(3))
        s.pause(start.addingTimeInterval(4))
        return s
    }

    @Test func messagesJSON() throws {
        let all: [Message] = [
            .templates([template]), .settings(settings), .run(run, summary: nil),
            .run(nil, summary: summary), .values(calories: 88, heartRate: 141),
        ]
        let expected = [
            #"{"vorlagen":{"_0":[{"aktiv":30,"auslaufen":10,"gleicheUebungen":false,"id":"00000000-0000-0000-0000-000000000001","name":"X","pause":15,"runden":2,"uebungen":[["a","b"]],"vorbereitung":5,"zirkel":2,"zirkelpause":20}]}}"#,
            #"{"einstellungen":{"_0":{"bildschirmAn":true,"coach":"daniel","countdownAb":3,"countdownLaenge":3,"health":true,"musikLeiser":true,"stimme":true,"symbol":"fit","tonsatz":"pfeife","vibration":true}}}"#,
            #"{"lauf":{"_0":{"angehalten":2,"beendet":false,"plan":{"phasen":[{"art":"vorbereitung","beginn":0,"dauer":5,"runde":1,"uebung":"a","zirkel":1},{"art":"aktiv","beginn":5,"dauer":30,"runde":1,"uebung":"a","zirkel":1},{"art":"pause","beginn":35,"dauer":15,"runde":1,"zirkel":1},{"art":"aktiv","beginn":50,"dauer":30,"runde":2,"uebung":"b","zirkel":1},{"art":"zirkelpause","beginn":80,"dauer":20,"runde":2,"zirkel":1},{"art":"aktiv","beginn":100,"dauer":30,"runde":1,"zirkel":2},{"art":"pause","beginn":130,"dauer":15,"runde":1,"zirkel":2},{"art":"aktiv","beginn":145,"dauer":30,"runde":2,"zirkel":2},{"art":"auslaufen","beginn":175,"dauer":10,"runde":2,"zirkel":2}],"runden":2,"zirkel":2},"sprung":26,"start":7000000,"uebersprungeneAktiv":1,"vorlage":{"aktiv":30,"auslaufen":10,"gleicheUebungen":false,"id":"00000000-0000-0000-0000-000000000001","name":"X","pause":15,"runden":2,"uebungen":[["a","b"]],"vorbereitung":5,"zirkel":2,"zirkelpause":20}}}}"#,
            #"{"lauf":{"ergebnis":{"dauer":5,"kalorien":9,"puls":140,"runden":2,"vorlage":"Z"}}}"#,
            #"{"werte":{"kalorien":88,"puls":141}}"#,
        ]
        #expect(try all.map { try json($0) } == expected)
    }
}
