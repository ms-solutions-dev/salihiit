import Core
import Foundation
import Testing

@testable import Storage

@MainActor @Suite struct StorageTests {
    let folder = FileManager.default.temporaryDirectory.appending(path: "store-\(UUID().uuidString)")

    @Test func firstLaunchBringsSamples() {
        let a = TemplateStore(folder: folder)
        #expect(a.templates.map(\.name) == ["Zirkel", "Tabata", "HIIT 40/20", "Plank"])
        #expect(a.selected?.name == "Zirkel")
    }

    @Test func templateSurvivesRestart() {
        let a = TemplateStore(folder: folder)
        var new = Template(name: "Push-ups", active: 45, rest: 15, rounds: 5)
        new.exercises = [["A", "B"]]
        a.save(new)
        let b = TemplateStore(folder: folder)
        #expect(b.templates.last == new)
        #expect(b.selection == new.id)
    }

    @Test func deleteDuplicateMove() {
        let a = TemplateStore(folder: folder)
        let tabata = a.templates[1].id
        a.duplicate(tabata, nameSuffix: "Copy")
        #expect(a.templates.last?.name == "Tabata Copy")
        a.delete(a.templates[0].id)
        #expect(a.templates.first?.id == tabata)
        a.move(from: [0], to: 2)
        #expect(a.templates[1].id == tabata)
    }

    @Test func changeIsReportedAdoptionIsNot() {
        let a = TemplateStore(folder: folder)
        var reported = 0
        a.onChange = { _ in reported += 1 }
        a.save(Template(name: "x", active: 10, rest: 5, rounds: 2))
        #expect(reported == 1)
        a.adopt(Template.samples)
        #expect(reported == 1)
        #expect(a.templates == Template.samples)
    }

    @Test func settingsOldStatesStayReadable() throws {
        let old = Data(#"{"stimme":true}"#.utf8)
        let e = try JSONDecoder().decode(Settings.self, from: old)
        #expect(e.voice && e.vibration && e.icon == .wordmark)
    }

    /// Liam and Jessica left the bundle on 22.11.2026; a stored choice moves to the voice of the same kind.
    @Test func removedCoachVoicesMoveToTheirSuccessor() throws {
        let liam = try JSONDecoder().decode(Settings.self, from: Data(#"{"coach":"liam"}"#.utf8))
        let jessica = try JSONDecoder().decode(Settings.self, from: Data(#"{"coach":"jessica"}"#.utf8))
        let elif = try JSONDecoder().decode(Settings.self, from: Data(#"{"coach":"elif"}"#.utf8))
        #expect(liam.coach == "charlie" && jessica.coach == "laura" && elif.coach == "elif")
    }

    @Test func settingsSurviveRestart() {
        let storage = UserDefaults(suiteName: "test-\(UUID().uuidString)")!
        let a = SettingsStore(storage: storage)
        a.values.icon = .ring
        #expect(SettingsStore(storage: storage).values.icon == .ring)
    }
}

@MainActor @Test func clocksSurviveRestart() {
    let storage = UserDefaults(suiteName: "clocks-\(UUID().uuidString)")!
    let a = ClockStore(storage: storage)
    a.stopwatch.start(Date(timeIntervalSinceReferenceDate: 100))
    a.laps.lap(Date(timeIntervalSinceReferenceDate: 50))
    let b = ClockStore(storage: storage)
    #expect(b.stopwatch.hasStarted && b.laps.isRunning)
}

@MainActor @Test func sampleNamesFollowLanguage() {
    let folder = FileManager.default.temporaryDirectory.appending(path: "names-\(UUID().uuidString)")
    var turkish = Template.samples
    turkish[0].name = "Devre"
    turkish[1].name = "My Tabata"
    let a = TemplateStore(folder: folder, samples: turkish)
    a.syncSampleNames([(["Zirkel", "Devre", "Circuit"], "Zirkel")])
    #expect(a.templates[0].name == "Zirkel")
    #expect(a.templates[1].name == "My Tabata")
    #expect(TemplateStore(folder: folder).templates[0].name == "Zirkel")
}

@Test func countdownOffKeepsLength() throws {
    var e = Settings()
    e.setLength(5)
    #expect(e.countdownFrom == 5)
    e.isCountdownOn = false
    #expect(e.countdownFrom == 0 && e.countdownLength == 5)
    e.isCountdownOn = true
    #expect(e.countdownFrom == 5)
    // An old state with "from 5" does not know the length yet.
    let old = try JSONDecoder().decode(Settings.self, from: Data(#"{"countdownAb":5}"#.utf8))
    #expect(old.countdownLength == 5)
}
