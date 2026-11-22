import Foundation
import HealthKit
import os

/// The watch's workout session: keeps the app awake during the workout, measures heart rate and
/// calories and stores an HIIT workout in Health at the end.
///
/// If saving to Apple Health is off, the session still runs so the signals do not fall asleep;
/// at the end the workout is discarded instead of saved.
@MainActor final class Workout: NSObject {
    private let store = HKHealthStore()
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?
    private let log = Logger(subsystem: "dev.ms-solutions.salihiit", category: "Workout")

    /// Reports the current heart rate (beats per minute).
    var onHeartRate: ((Int) -> Void)?

    var isRunning: Bool { session != nil }

    func requestPermission() async {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        let load: Set<HKObjectType> = [
            HKQuantityType(.heartRate), HKQuantityType(.activeEnergyBurned), HKObjectType.workoutType(),
        ]
        try? await store.requestAuthorization(
            toShare: [HKObjectType.workoutType(), HKQuantityType(.activeEnergyBurned)], read: load)
    }

    func start(at start: Date = .now) {
        guard session == nil, HKHealthStore.isHealthDataAvailable() else { return }
        let config = HKWorkoutConfiguration()
        config.activityType = .highIntensityIntervalTraining
        config.locationType = .indoor
        do {
            let s = try HKWorkoutSession(healthStore: store, configuration: config)
            let b = s.associatedWorkoutBuilder()
            b.dataSource = HKLiveWorkoutDataSource(healthStore: store, workoutConfiguration: config)
            b.delegate = self
            session = s
            builder = b
            s.startActivity(with: start)
            Task {
                try? await b.beginCollection(at: start)
            }
        } catch {
            log.error("Workout start: \(error.localizedDescription, privacy: .public)")
        }
    }

    func pause() { session?.pause() }
    func resume() { session?.resume() }

    /// Ends the session and returns calories and average heart rate.
    func end(save: Bool) async -> (calories: Int?, heartRate: Int?) {
        guard let s = session, let b = builder else { return (nil, nil) }
        session = nil
        builder = nil
        s.end()
        let now = Date.now
        try? await b.endCollection(at: now)
        let kcal = b.statistics(for: HKQuantityType(.activeEnergyBurned))?.sumQuantity()?.doubleValue(
            for: .kilocalorie())
        let heartRate = b.statistics(for: HKQuantityType(.heartRate))?.averageQuantity()?
            .doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
        if save {
            _ = try? await b.finishWorkout()
        } else {
            b.discardWorkout()
        }
        return (kcal.map { Int($0.rounded()) }, heartRate.map { Int($0.rounded()) })
    }
}

extension Workout: HKLiveWorkoutBuilderDelegate {
    nonisolated func workoutBuilder(
        _ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf types: Set<HKSampleType>
    ) {
        guard types.contains(HKQuantityType(.heartRate)),
            let value = workoutBuilder.statistics(for: HKQuantityType(.heartRate))?.mostRecentQuantity()?
                .doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
        else { return }
        let heartRate = Int(value.rounded())
        Task { @MainActor in self.onHeartRate?(heartRate) }
    }

    nonisolated func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}
}
