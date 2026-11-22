import Foundation
import Testing

@testable import Signals

@Suite struct CoachVoiceTests {
    let voices = [
        CoachVoice(id: "ben", name: "Ben", language: "de", description: ["en": "male"]),
        CoachVoice(id: "elif", name: "Elif", language: "tr", description: ["en": "female"]),
        CoachVoice(id: "charlie", name: "Charlie", language: "en", description: ["en": "male"]),
        CoachVoice(id: "hasan", name: "Hasan", language: "tr", description: ["en": "male"]),
    ]

    /// The device language comes first, the rest keeps the bundle order and nothing is dropped.
    @Test func deviceLanguageFirst() {
        #expect(CoachVoice.ordered(voices, for: "tr").map(\.id) == ["elif", "hasan", "ben", "charlie"])
        #expect(CoachVoice.ordered(voices, for: "fr").map(\.id) == ["ben", "elif", "charlie", "hasan"])
    }

    /// The list in the bundle carries the language of each voice.
    @Test func bundleListReadsLanguage() throws {
        let json =
            #"[{"id":"elif","name":"Elif","sprache":"tr","geschlecht":"w","beschreibung":{"en":"female"}}]"#
        let decoded = try JSONDecoder().decode([CoachVoice].self, from: Data(json.utf8))
        #expect(decoded.first?.language == "tr")
    }
}
