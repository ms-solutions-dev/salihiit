import Core
import Foundation
import Observation

/// The sound sets offered in the settings.
public enum SoundSet: String, Codable, Sendable, CaseIterable {
    case whistle = "pfeife"
    case bell = "glocke"
    case gong
    case digital
    case beep = "piep"
}

/// The app icons. `nil` for the system means the primary icon.
public enum AppIcon: String, Codable, Sendable, CaseIterable {
    case wordmark = "wortmarke"
    case ring
    case stopwatch = "stoppuhr"
    case monogram = "monogramm"
    case pulse = "puls"
    /// The raw value stays "fit": that is what the icon was called in an earlier build, and stored
    /// settings must stay readable.
    case dark = "fit"

    /// Name of the icon set for `setAlternateIconName`, `nil` for the primary icon.
    public var iconSetName: String? {
        switch self {
        case .wordmark: nil
        case .ring: "AppIconRing"
        case .stopwatch: "AppIconStoppuhr"
        case .monogram: "AppIconMonogramm"
        case .pulse: "AppIconPuls"
        case .dark: "AppIconDunkel"
        }
    }

    /// The preview image in the asset catalog.
    public var preview: String {
        "Vorschau" + (iconSetName ?? "AppIcon")
    }
}

/// All switches of the app. They go to the watch as a whole.
public struct Settings: Codable, Sendable, Hashable {
    public var soundSet: SoundSet = .whistle
    /// From which second the countdown counts: 0 is off, otherwise `countdownLength`.
    public var countdownFrom = 3
    /// The chosen countdown length (3 or 5); it is kept while the countdown is off.
    public var countdownLength = 3

    /// Countdown on or off, without losing the chosen length.
    public var isCountdownOn: Bool {
        get { countdownFrom > 0 }
        set { countdownFrom = newValue ? countdownLength : 0 }
    }

    /// Sets the length; a running countdown adopts it immediately.
    public mutating func setLength(_ n: Int) {
        countdownLength = n
        if countdownFrom > 0 { countdownFrom = n }
    }
    /// Coach voice for the countdown (`Stimmen/stimmen.json`); `nil` means sounds.
    public var coach: String?

    /// Voices that left the bundle on 22.11.2026 and the voice of the same kind that took their place,
    /// so a stored choice keeps counting instead of falling silent.
    static let renamedCoaches = ["liam": "charlie", "jessica": "laura"]
    public var voice = false
    public var vibration = true
    public var lowerMusic = true
    public var keepScreenOn = true
    public var health = true
    public var icon: AppIcon = .wordmark

    public init() {}

    // Switches added in later builds must not make older stored settings unreadable.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let s = Settings.standard
        soundSet = try c.decodeIfPresent(SoundSet.self, forKey: .soundSet) ?? s.soundSet
        // Until build 1 there was only "countdown on/off" (3 seconds).
        let old = try c.decodeIfPresent(Bool.self, forKey: .countdown)
        countdownFrom =
            try c.decodeIfPresent(Int.self, forKey: .countdownFrom) ?? (old == false ? 0 : s.countdownFrom)
        coach = try c.decodeIfPresent(String.self, forKey: .coach).map { Self.renamedCoaches[$0] ?? $0 }
        countdownLength =
            try c.decodeIfPresent(Int.self, forKey: .countdownLength)
            ?? (countdownFrom > 0 ? countdownFrom : 3)
        voice = try c.decodeIfPresent(Bool.self, forKey: .voice) ?? s.voice
        vibration = try c.decodeIfPresent(Bool.self, forKey: .vibration) ?? s.vibration
        lowerMusic = try c.decodeIfPresent(Bool.self, forKey: .lowerMusic) ?? s.lowerMusic
        keepScreenOn = try c.decodeIfPresent(Bool.self, forKey: .keepScreenOn) ?? s.keepScreenOn
        health = try c.decodeIfPresent(Bool.self, forKey: .health) ?? s.health
        icon = try c.decodeIfPresent(AppIcon.self, forKey: .icon) ?? s.icon
    }

    public static let standard = Settings()

    private enum CodingKeys: String, CodingKey {
        case soundSet = "tonsatz"
        case countdown
        case countdownFrom = "countdownAb"
        case countdownLength = "countdownLaenge"
        case coach
        case voice = "stimme"
        case vibration
        case lowerMusic = "musikLeiser"
        case keepScreenOn = "bildschirmAn"
        case health
        case icon = "symbol"
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(soundSet, forKey: .soundSet)
        try c.encode(countdownFrom, forKey: .countdownFrom)
        try c.encode(countdownLength, forKey: .countdownLength)
        try c.encodeIfPresent(coach, forKey: .coach)
        try c.encode(voice, forKey: .voice)
        try c.encode(vibration, forKey: .vibration)
        try c.encode(lowerMusic, forKey: .lowerMusic)
        try c.encode(keepScreenOn, forKey: .keepScreenOn)
        try c.encode(health, forKey: .health)
        try c.encode(icon, forKey: .icon)
    }
}

/// Keeps the settings in the App Group's UserDefaults.
@MainActor @Observable public final class SettingsStore {
    public var values: Settings {
        didSet {
            guard values != oldValue else { return }
            write()
            onChange?(values)
        }
    }

    @ObservationIgnored public var onChange: ((Settings) -> Void)?
    private let storage: UserDefaults
    private static let key = "einstellungen"

    public init(storage: UserDefaults? = nil) {
        let s = storage ?? UserDefaults(suiteName: Identifiers.appGroup) ?? .standard
        self.storage = s
        values =
            s.data(forKey: Self.key).flatMap {
                try? JSONDecoder().decode(Settings.self, from: $0)
            }
            ?? .standard
    }

    /// Adopts the settings from the other device without reporting them back.
    public func adopt(_ new: Settings) {
        let report = onChange
        onChange = nil
        values = new
        onChange = report
    }

    private func write() {
        storage.set(try? JSONEncoder().encode(values), forKey: Self.key)
    }
}
