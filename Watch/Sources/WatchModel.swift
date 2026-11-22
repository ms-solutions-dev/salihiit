import Connectivity
import Control
import Core
import Foundation
import Observation
import Storage

/// What the watch screens share. The watch works standalone; workout and link hook in.
@MainActor @Observable final class WatchModel {
    let store = TemplateStore()
    let settings = SettingsStore()
    let clocks = ClockStore()
    let training: Training
    /// Live heart rate from the workout, `nil` without a measurement.
    var heartRate: Int?

    private let workout = Workout()
    private let link = WatchLink()
    private var permissionAsked = false

    init() {
        training = Training(settings: settings)
        settings.onChange = { [weak self] _ in self?.training.settingsChanged() }
        workout.onHeartRate = { [weak self] p in self?.heartRate = p }
        training.observe { [weak self] run, _ in self?.followWorkout(run) }
        connect()
    }

    /// Templates and settings come from the iPhone, the run travels in both directions.
    private func connect() {
        training.observe { [weak self] run, origin in
            guard let self, origin == .local else { return }
            link.send(.run(run, summary: run == nil ? training.summary : nil))
        }
        onValues = { [weak self] k, p in self?.link.send(.values(calories: k, heartRate: p)) }
        link.onReceive = { [weak self] n in
            guard let self else { return }
            switch n {
            case .templates(let list): store.adopt(list)
            case .settings(let e): settings.adopt(e)
            case .run(let run, let e): training.adopt(run, summary: e)
            case .values: break
            }
        }
        link.activate()
    }

    /// Keeps the workout session in step with the run.
    private func followWorkout(_ run: Timekeeper?) {
        guard let run else {
            guard workout.isRunning else { return }
            let save = settings.values.health
            Task {
                let values = await workout.end(save: save)
                training.attach(calories: values.calories, heartRate: values.heartRate)
                heartRate = nil
                onValues?(values.calories, values.heartRate)
            }
            return
        }
        if !workout.isRunning {
            workout.start(at: run.start)
        } else if run.isRunning {
            workout.resume()
        } else {
            workout.pause()
        }
    }

    /// Calories and heart rate after the workout, for the iPhone.
    var onValues: ((Int?, Int?) -> Void)?

    func start(_ template: Template) {
        store.selection = template.id
        Task {
            if !permissionAsked {
                permissionAsked = true
                await workout.requestPermission()
            }
            training.start(template)
        }
    }
}
