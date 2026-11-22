import Core
import Foundation
import Storage

/// What travels between phone and watch.
///
/// No second ever travels over the line, only complete states: both devices compute their display
/// from the same timekeeper. Whoever changes something sends the new state; the other device adopts
/// it without sending it back.
public enum Message: Codable, Sendable, Equatable {
    /// iPhone → watch, via the application context (the newest state wins).
    case templates([Template])
    case settings(Settings)
    /// In both directions; `nil` means ended, then with a summary.
    case run(Timekeeper?, summary: WorkoutSummary?)
    /// Watch → iPhone after the workout.
    case values(calories: Int?, heartRate: Int?)

    static let key = "n"

    // The wire format predates the English rename; keep the original names.
    private enum CodingKeys: String, CodingKey {
        case templates = "vorlagen"
        case settings = "einstellungen"
        case run = "lauf"
        case values = "werte"
    }

    private enum TemplatesCodingKeys: String, CodingKey { case _0 }
    private enum SettingsCodingKeys: String, CodingKey { case _0 }

    private enum RunCodingKeys: String, CodingKey {
        case _0
        case summary = "ergebnis"
    }

    private enum ValuesCodingKeys: String, CodingKey {
        case calories = "kalorien"
        case heartRate = "puls"
    }

    public func encoded() throws -> [String: Any] {
        [Self.key: try JSONEncoder().encode(self)]
    }

    public static func decoded(_ content: [String: Any]) -> Message? {
        guard let data = content[key] as? Data else { return nil }
        return try? JSONDecoder().decode(Message.self, from: data)
    }
}
