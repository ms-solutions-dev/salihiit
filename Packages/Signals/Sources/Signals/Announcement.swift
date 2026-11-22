import Core
import Design
import Foundation
import Storage

/// What sounds, is spoken and is felt for a signal.
public struct Announcement: Sendable, Hashable {
    /// Raw values are part of the bundled file names (`Toene/<set>-<sound>`).
    public enum Sound: String, Sendable {
        case short = "kurz"
        case long = "lang"
        case end = "ende"
    }
    public enum Haptic: Sendable { case tap, phase, end }

    public let sound: Sound?
    public let text: String?
    public let haptic: Haptic?
    /// A recorded announcement instead of the sound, for example `Stimmen/daniel/3`.
    public var recording: String?

    public init(sound: Sound?, text: String?, haptic: Haptic?, recording: String? = nil) {
        self.sound = sound
        self.text = text
        self.haptic = haptic
        self.recording = recording
    }

    /// Path in the bundle without extension, for example `Toene/pfeife-lang` or `Stimmen/daniel/3`.
    public func file(_ soundSet: SoundSet) -> String? {
        recording ?? sound.map { "Toene/\(soundSet.rawValue)-\($0.rawValue)" }
    }

    public static func make(_ e: Event, settings: Settings) -> Announcement {
        let voice = settings.voice
        let haptic = settings.vibration
        switch e.kind {
        case .countdown(let n):
            if let coach = settings.coach {
                return Announcement(
                    sound: nil, text: nil, haptic: haptic ? .tap : nil, recording: "Stimmen/\(coach)/\(n)"
                )
            }
            return Announcement(sound: .short, text: voice ? "\(n)" : nil, haptic: haptic ? .tap : nil)
        case .phaseStart(let p):
            let text = [p.kind.titleText, p.kind == .active ? p.exercise : nil].compactMap { $0 }.joined(
                separator: ", ")
            return Announcement(sound: .long, text: voice ? text : nil, haptic: haptic ? .phase : nil)
        case .halfway:
            return Announcement(sound: nil, text: voice ? localized("announce.halfway") : nil, haptic: nil)
        case .finished:
            return Announcement(
                sound: .end, text: voice ? localized("announce.done") : nil, haptic: haptic ? .end : nil
            )
        }
    }
}
