import Core
import Foundation
import Storage
import UserNotifications

/// The safety net under the signals: if the app falls asleep in the background after all,
/// at least the phase changes sound as a notification with the same tone.
///
/// iOS keeps at most 64 notifications pending; 60 phase changes suffice for any usual workout.
@MainActor final class NotificationNet {
    // Only in a real app: in `swift test` without an app bundle `current()` aborts with signal 6.
    private var center: UNUserNotificationCenter? {
        Bundle.main.bundlePath.hasSuffix(".app") ? .current() : nil
    }
    private var scheduled: [String] = []

    func requestPermission() async {
        _ = try? await center?.requestAuthorization(options: [.alert, .sound])
    }

    func schedule(_ run: Timekeeper, settings: Settings) {
        clear()
        let list = SignalSchedule.upcoming(
            run, from: .now.addingTimeInterval(1.5), settings: settings, atMost: 60,
            phasesOnly: true)
        for f in list {
            let content = UNMutableNotificationContent()
            let announcement = Announcement.make(f.event, settings: settings)
            switch f.event.kind {
            case .phaseStart(let p):
                content.title = p.kind.titleText + (p.exercise.map { " · " + $0 } ?? "")
                content.body = run.template.name
            default:
                content.title = run.template.name
            }
            // On the watch the workout session keeps the app awake; the default tone is enough there.
            #if os(watchOS)
                content.sound = .default
            #else
                if let file = announcement.file(settings.soundSet) {
                    content.sound = UNNotificationSound(named: UNNotificationSoundName("\(file).wav"))
                }
            #endif
            content.interruptionLevel = .timeSensitive
            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: max(1, f.time.timeIntervalSinceNow), repeats: false)
            center?.add(UNNotificationRequest(identifier: f.identifier, content: content, trigger: trigger))
            scheduled.append(f.identifier)
        }
    }

    func withdraw(_ identifier: String) {
        center?.removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    func clear() {
        center?.removePendingNotificationRequests(withIdentifiers: scheduled)
        scheduled = []
    }
}
