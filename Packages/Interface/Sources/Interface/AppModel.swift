import Connectivity
import Control
import Core
import Design
import Foundation
import Observation
import Storage

#if canImport(UIKit)
    import UIKit
#endif

/// What all iPhone screens share: store, settings, clocks and the workout.
@MainActor @Observable public final class AppModel {
    public let store: TemplateStore
    public let settings: SettingsStore
    public let clocks: ClockStore
    public let training: Training
    /// The settings as a sheet above each of the three screens.
    public var isSettingsOpen = false
    /// The selected mode; in landscape the screens place their own bar.
    public var mode: Mode = .interval

    /// For the link to the watch.
    @ObservationIgnored public var settingsReported: ((Settings) -> Void)?
    @ObservationIgnored private let island = IslandController()
    @ObservationIgnored private let link = WatchLink()
    @ObservationIgnored private var permissionAsked = false

    public init(
        store: TemplateStore = TemplateStore(samples: AppModel.samples),
        settings: SettingsStore = SettingsStore(),
        clocks: ClockStore = ClockStore()
    ) {
        self.store = store
        self.settings = settings
        self.clocks = clocks
        training = Training(settings: settings)
        store.syncSampleNames([
            (["Zirkel", "Devre", "Circuit"], localized("sample.circuit")),
            (["Plank"], localized("sample.plank")),
        ])

        settings.onChange = { [weak self] e in
            // A switch during the workout (for example voice on) takes effect immediately.
            self?.training.settingsChanged()
            self?.keepScreenAwake()
            self?.settingsReported?(e)
        }
        training.signals.onPhaseChange = { [weak self] in self?.island.show(self?.training.run) }
        training.observe { [weak self] run, _ in
            self?.island.show(run)
            self?.keepScreenAwake()
        }
        RemoteControl.perform = { [weak self] command in self?.training.perform(command) }
        connect()
        // A Live Activity left over from an aborted run belongs to no workout any more.
        island.show(nil)
    }

    /// The sample templates with names in the device language; "Tabata" and "HIIT" are called that everywhere.
    public static var samples: [Template] {
        var b = Template.samples
        b[0].name = localized("sample.circuit")
        b[3].name = localized("sample.plank")
        return b
    }

    public func start(_ template: Template, at time: Date = .now) {
        store.selection = template.id
        training.start(template, at: time)
        // Wake the watch app so its workout runs along.
        link.wakeWatch()
    }

    /// Asks for notification permission on first open, not at the start: otherwise the system dialog
    /// would cover the first running timer.
    public func requestPermission() async {
        guard !permissionAsked else { return }
        #if DEBUG
            // Screenshots: the system dialog would cover the image.
            if ProcessInfo.processInfo.environment["SALIHIIT_SCREEN"] != nil { return }
        #endif
        permissionAsked = true
        await training.signals.requestPermission()
    }

    /// Scene change: in the background, notifications are ready as a safety net.
    public func foreground(_ on: Bool) {
        training.signals.foreground(on)
    }

    /// Phone and watch: templates and settings go to the watch, the run in both directions,
    /// calories and heart rate come back.
    private func connect() {
        store.onChange = { [weak self] list in self?.link.send(.templates(list)) }
        settingsReported = { [weak self] e in self?.link.send(.settings(e)) }
        training.observe { [weak self] run, origin in
            guard let self, origin == .local else { return }
            link.send(.run(run, summary: run == nil ? training.summary : nil))
        }
        link.onReceive = { [weak self] n in
            guard let self else { return }
            switch n {
            case .run(let run, let e): training.adopt(run, summary: e)
            case .values(let k, let p): training.attach(calories: k, heartRate: p)
            case .templates, .settings: break  // only goes from the iPhone to the watch
            }
        }
        link.onConnected = { [weak self] in
            guard let self else { return }
            link.send(.templates(store.templates))
            link.send(.settings(settings.values))
        }
        link.activate()
    }

    /// During a workout the screen stays on (configurable).
    private func keepScreenAwake() {
        #if canImport(UIKit)
            UIApplication.shared.isIdleTimerDisabled =
                training.run != nil && settings.values.keepScreenOn
        #endif
    }
}
