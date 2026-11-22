import HealthKit
import WatchKit

/// Accepts the wake-up from the iPhone (`startWatchApp(with:)`). The workout itself starts as soon as
/// the run arrives over the link; waking the app is all that is needed here.
final class WatchDelegate: NSObject, WKApplicationDelegate {
    func handle(_ workoutConfiguration: HKWorkoutConfiguration) {}
}
