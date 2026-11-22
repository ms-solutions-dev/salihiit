import Foundation
import os

#if os(iOS) || os(watchOS)
    import AVFoundation
#endif
#if os(iOS)
    import UIKit
#elseif os(watchOS)
    import WatchKit
#endif

/// Plays sounds, speaks and vibrates; keeps the audio session awake in the background.
///
/// The session runs as `.playback` with `.mixWithOthers` so other music apps keep playing.
/// A loop of silence keeps it active during the workout; only that way do the signals keep
/// running while locked.
///
/// Ducking: every reconfiguration of the session resets the output and crackles in a playing
/// sound. So the session is only switched at window boundaries: on one second before the first
/// signal of a series, off after the last one, never in the middle of a countdown.
/// Set the session up once, then leave it alone.
@MainActor final class SoundPlayer {
    private let log = Logger(subsystem: "dev.ms-solutions.salihiit", category: "Signals")
    #if os(iOS) || os(watchOS)
        private var silence: AVAudioPlayer?
        /// Two players per file: the countdown schedules the same file one second ahead while the
        /// previous one is still sounding; a single player would cut it off.
        private var players: [String: [AVAudioPlayer]] = [:]
        private let speaker = AVSpeechSynthesizer()
        private var unduckTask: Task<Void, Never>?
        private var ducked = false
        private var active = false
    #endif

    init() {
        #if os(iOS) || os(watchOS)
            observe()
        #endif
    }

    /// Stay awake while a workout runs.
    func keepAwake(_ on: Bool) {
        #if os(iOS) || os(watchOS)
            if on {
                unduckTask?.cancel()
                guard silence == nil else { return }
                prepare()
                guard let url = Self.url("Toene/stille") else {
                    log.error("Toene/stille.wav is missing from the bundle")
                    return
                }
                silence = try? AVAudioPlayer(contentsOf: url)
                silence?.numberOfLoops = -1
                silence?.play()
            } else {
                // Only release after the end sound, otherwise "Done" gets cut off.
                unduckTask?.cancel()
                unduckTask = Task { [weak self] in
                    try? await Task.sleep(for: .seconds(3))
                    guard let self, !Task.isCancelled else { return }
                    self.silence?.stop()
                    self.silence = nil
                    try? AVAudioSession.sharedInstance().setActive(
                        false, options: .notifyOthersOnDeactivation)
                    self.active = false
                    self.ducked = false
                }
            }
        #endif
    }

    /// Plays a file exactly at the date `at` (or immediately), timed precisely on the audio device's
    /// clock instead of a woken task. Returns the duration.
    @discardableResult func schedule(_ soundSet: String?, at: Date? = nil) -> Double {
        #if os(iOS) || os(watchOS)
            guard let soundSet, let p = freePlayer(soundSet) else { return 0 }
            p.currentTime = 0
            let leadTime = max(0, at?.timeIntervalSinceNow ?? 0)
            if leadTime > 0.005 {
                p.play(atTime: p.deviceCurrentTime + leadTime)
            } else {
                p.play()
            }
            return p.duration
        #else
            return 0
        #endif
    }

    /// Speaks a text with the system voice (phase and exercise names).
    func speak(_ text: String) {
        #if os(iOS) || os(watchOS)
            let u = AVSpeechUtterance(string: text)
            u.voice = AVSpeechSynthesisVoice(language: Self.voiceLanguage)
            u.rate = AVSpeechUtteranceDefaultSpeechRate * 1.05
            speaker.speak(u)
        #endif
    }

    /// Stops scheduled files that have not sounded yet, for example when pausing the workout.
    func discardScheduled() {
        #if os(iOS) || os(watchOS)
            for p in players.values.joined() where p.isPlaying { p.stop() }
        #endif
    }

    /// Sets up the session without ducking if it is not up yet.
    func prepare() {
        #if os(iOS) || os(watchOS)
            guard !active else { return }
            session(duck: false)
        #endif
    }

    /// Music quieter for a series of signals. No reconfiguration if the state is already right.
    func duck() {
        #if os(iOS) || os(watchOS)
            unduckTask?.cancel()
            guard !ducked else { return }
            session(duck: true)
            ducked = true
        #endif
    }

    /// Releases ducking after `seconds` if no new signal is due by then.
    func unduck(to seconds: Double) {
        #if os(iOS) || os(watchOS)
            guard ducked else { return }
            unduckTask?.cancel()
            unduckTask = Task { [weak self] in
                try? await Task.sleep(for: .seconds(seconds))
                guard let self, !Task.isCancelled, !self.speaker.isSpeaking else { return }
                // The music only gets loud again once the session was briefly inactive. While playback is
                // running it cannot be released ("busy").
                self.silence?.pause()
                try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
                self.session(duck: false)
                self.ducked = false
                self.silence?.play()
            }
        #endif
    }

    /// Whether a recording exists in the bundle.
    static func exists(_ path: String) -> Bool {
        #if os(iOS) || os(watchOS)
            url(path) != nil
        #else
            true
        #endif
    }

    func stop() {
        #if os(iOS) || os(watchOS)
            speaker.stopSpeaking(at: .immediate)
            for p in players.values.joined() { p.stop() }
        #endif
    }

    // MARK: Internal

    #if os(iOS) || os(watchOS)
        private func freePlayer(_ name: String) -> AVAudioPlayer? {
            if players[name] == nil {
                guard let url = Self.url(name) else {
                    log.error("Sound missing: \(name, privacy: .public)")
                    return nil
                }
                players[name] = (0..<2).compactMap { _ in
                    let p = try? AVAudioPlayer(contentsOf: url)
                    p?.prepareToPlay()
                    return p
                }
            }
            let list = players[name] ?? []
            return list.first { !$0.isPlaying } ?? list.first
        }

        /// Interruptions: a call, Siri or an app that plays exclusively takes the session away from us.
        /// Afterwards the silence loop did not continue and the app was put to sleep while locked.
        /// If the media services restart, all players are dead and must be recreated.
        private func observe() {
            Task { [weak self] in
                for await notification in NotificationCenter.default.notifications(
                    named: AVAudioSession.interruptionNotification)
                {
                    guard let self,
                        let raw = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
                        AVAudioSession.InterruptionType(rawValue: raw) == .ended
                    else { continue }
                    self.resumeSession()
                }
            }
            Task { [weak self] in
                for await _ in NotificationCenter.default.notifications(
                    named: AVAudioSession.mediaServicesWereResetNotification)
                {
                    guard let self else { continue }
                    self.players = [:]
                    let wasRunning = self.silence != nil
                    self.silence = nil
                    self.resumeSession()
                    if wasRunning { self.keepAwake(true) }
                }
            }
        }

        private func resumeSession() {
            active = false
            ducked = false
            guard silence != nil else { return }
            session(duck: false)
            silence?.play()
        }

        /// `Toene/pfeife-kurz` or `Stimmen/liam/3`; WAV before m4a. If the file is not in the
        /// subfolder (XcodeGen flattens groups), the top of the bundle is searched.
        static func url(_ path: String) -> URL? {
            let parts = path.split(separator: "/").map(String.init)
            let name = parts.last ?? path
            let folder = parts.dropLast().joined(separator: "/")
            for fileExtension in ["wav", "m4a"] {
                if let u = Bundle.main.url(
                    forResource: name, withExtension: fileExtension, subdirectory: folder)
                {
                    return u
                }
            }
            return folder.hasPrefix("Toene") ? Bundle.main.url(forResource: name, withExtension: "wav") : nil
        }

        private func session(duck: Bool) {
            let s = AVAudioSession.sharedInstance()
            do {
                try s.setCategory(
                    .playback, mode: .default,
                    options: duck ? [.mixWithOthers, .duckOthers] : [.mixWithOthers])
                try s.setActive(true)
                active = true
            } catch {
                log.error("Audio session: \(error.localizedDescription, privacy: .public)")
            }
        }

        static var voiceLanguage: String {
            switch Locale.preferredLanguages.first?.prefix(2) {
            case "de": "de-DE"
            case "tr": "tr-TR"
            default: "en-US"
            }
        }
    #endif

    func haptic(_ kind: Announcement.Haptic?) {
        guard let kind else { return }
        #if os(iOS)
            switch kind {
            case .tap: UIImpactFeedbackGenerator(style: .light).impactOccurred()
            case .phase: UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            case .end: UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        #elseif os(watchOS)
            switch kind {
            case .tap: WKInterfaceDevice.current().play(.click)
            case .phase: WKInterfaceDevice.current().play(.start)
            case .end: WKInterfaceDevice.current().play(.success)
            }
        #endif
    }
}
