import Core
import Foundation
import Storage
import os

/// Accompanies a run with signals: sleeps until the next due event, plays it, sleeps again.
/// Every change to the run (pause, skip) reschedules.
///
/// Everything is computed from the timekeeper, so a late wake-up catches nothing up: signals older
/// than a second are dropped instead of all sounding at once.
@MainActor public final class SignalEngine {
    private let players = SoundPlayer()
    private let net = NotificationNet()
    private let probe = TimingProbe()
    private var task: Task<Void, Never>?
    private var run: Timekeeper?
    private var settings = Settings.standard
    private var inForeground = true
    private var hapticsOnly = false
    /// At every phase start; the Live Activity then sends its new state.
    public var onPhaseChange: (() -> Void)?

    public init() {}

    /// Adopts a new state. `nil` ends the accompaniment.
    /// - Parameter hapticsOnly: The workout runs on the other device and is only mirrored here.
    ///   Nothing sounds here then, otherwise phone and watch count at the same time and it echoes.
    ///   The watch still vibrates on the wrist.
    public func follow(_ run: Timekeeper?, settings: Settings, hapticsOnly: Bool = false) {
        self.run = run
        self.settings = settings
        self.hapticsOnly = hapticsOnly
        task?.cancel()
        // What was already scheduled for the next second no longer applies after pause or skip.
        players.discardScheduled()
        guard let run, !run.ended else {
            players.keepAwake(false)
            net.clear()
            return
        }
        // Stay awake while paused too: resuming from the lock screen needs a living app.
        if !hapticsOnly {
            players.keepAwake(true)
            if !inForeground { net.schedule(run, settings: settings) }
        }
        guard run.isRunning else { return }
        task = Task { [weak self] in await self?.loop() }
    }

    /// The app moves to the background or foreground; notifications are only pending in the background.
    public func foreground(_ on: Bool) {
        inForeground = on
        if on {
            net.clear()
        } else if let run, run.isRunning, !hapticsOnly {
            net.schedule(run, settings: settings)
        }
    }

    /// Plays `count` countdown sounds and the phase sound of a sound set (Settings › Voices);
    /// with 0 only the phase sound.
    public func preview(_ soundSet: SoundSet, count: Int) {
        let short = Announcement(sound: .short, text: nil, haptic: nil)
        let long = Announcement(sound: .long, text: nil, haptic: nil)
        play(Array(repeating: short.file(soundSet), count: count) + [long.file(soundSet)])
    }

    /// Plays the countdown of a coach voice from `count` down and then the phase sound.
    public func preview(coach: String, soundSet: SoundSet, count: Int) {
        let long = Announcement(sound: .long, text: nil, haptic: nil)
        play((1...max(1, count)).reversed().map { "Stimmen/\(coach)/\($0)" } + [long.file(soundSet)])
    }

    private var previewTask: Task<Void, Never>?

    private func play(_ files: [String?]) {
        previewTask?.cancel()
        previewTask = Task { [weak self] in
            for d in files {
                guard let self, !Task.isCancelled else { return }
                self.players.prepare()
                self.players.schedule(d)
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }

    /// Asks once for notification permission (the background safety net).
    public func requestPermission() async {
        await net.requestPermission()
    }

    private func loop() async {
        while !Task.isCancelled, let run {
            guard let f = SignalSchedule.next(run, from: .now, settings: settings) else { return }
            // Wake up one second early, withdraw the notification that would carry the same signal,
            // and schedule the sound precisely on the audio device's clock.
            let lead = f.time.timeIntervalSinceNow - 1
            if lead > 0 { try? await Task.sleep(for: .seconds(lead), tolerance: .milliseconds(50)) }
            guard !Task.isCancelled else { return }
            net.withdraw(f.identifier)
            var announcement = Announcement.make(f.event, settings: settings)
            // A chosen voice that no longer exists in this build: sound instead of silence.
            if let a = announcement.recording, !SoundPlayer.exists(a) {
                announcement = Announcement(sound: .short, text: nil, haptic: announcement.haptic)
            }
            var duration = 0.0
            if !hapticsOnly, f.time.timeIntervalSinceNow > -0.3 {
                // Reconfigure the session before the sound, never during it.
                if settings.lowerMusic { players.duck() }
                duration = players.schedule(announcement.file(settings.soundSet), at: f.time)
            }
            let remaining = f.time.timeIntervalSinceNow
            // Tight tolerance: without it the system coalesces timers by up to a quarter second.
            if remaining > 0 { try? await Task.sleep(for: .seconds(remaining), tolerance: .milliseconds(5)) }
            guard !Task.isCancelled else { return }
            let deviation = -f.time.timeIntervalSinceNow
            let played = deviation < 1
            if played {
                players.haptic(announcement.haptic)
                if !hapticsOnly, let text = announcement.text {
                    players.speak(text)
                    duration = max(duration, 1.2)
                }
                // If the next signal follows right away (countdown), the music stays ducked.
                let next = SignalSchedule.next(
                    run, from: .now.addingTimeInterval(0.2), settings: settings)
                if next.map({ $0.time.timeIntervalSinceNow > 2.5 }) ?? true {
                    players.unduck(to: duration + 0.3)
                }
            }
            probe.report(
                f, deviation: deviation, played: played && !hapticsOnly, foreground: inForeground)
            if case .phaseStart = f.event.kind { onPhaseChange?() }
            if case .finished = f.event.kind { return }
            // Not the same event twice: just past the full second.
            try? await Task.sleep(for: .milliseconds(60))
        }
    }
}

/// Measures how punctually the signals arrive. Writes to the system log and to
/// `signale.log` in the App Group so a device test can be reviewed afterwards.
@MainActor final class TimingProbe {
    private let log = Logger(subsystem: "dev.ms-solutions.salihiit", category: "Probe")
    private let file: URL? = FileManager.default
        .containerURL(forSecurityApplicationGroupIdentifier: Identifiers.appGroup)?
        .appending(path: "signale.log")

    static func short(_ kind: Event.Kind) -> String {
        switch kind {
        case .phaseStart(let p): "phaseStart-\(p.kind.rawValue)"
        case .countdown(let n): "countdown-\(n)"
        case .halfway: "halfway"
        case .finished: "finished"
        }
    }

    func report(_ f: DueSignal, deviation: Double, played: Bool, foreground: Bool) {
        let ms = Int(deviation * 1000)
        let row =
            "\(ISO8601DateFormatter().string(from: f.time)) t=\(f.event.time) \(Self.short(f.event.kind)) "
            + "\(ms) ms \(played ? "played" : "silent/discarded") \(foreground ? "foreground" : "background")\n"
        log.info("\(row, privacy: .public)")
        guard let file, let data = row.data(using: .utf8) else { return }
        if let h = try? FileHandle(forWritingTo: file) {
            h.seekToEndOfFile()
            h.write(data)
            try? h.close()
        } else {
            try? data.write(to: file)
        }
    }
}
