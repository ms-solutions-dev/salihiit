import Foundation
import os

#if canImport(WatchConnectivity)
    import WatchConnectivity
#endif
#if os(iOS)
    import HealthKit
#endif

/// The line between phone and watch via WatchConnectivity.
///
/// - Templates and settings: application context, which arrives even while the watch sleeps.
/// - Run and values: immediately as a message if the other device is reachable, otherwise queued
///   (`transferUserInfo`). Without a connection each device keeps running on its own.
@MainActor public final class WatchLink: NSObject {
    /// Every message from the other device.
    public var onReceive: ((Message) -> Void)?
    /// The connection is up; time to send our own state.
    public var onConnected: (() -> Void)?
    private let log = Logger(subsystem: "dev.ms-solutions.salihiit", category: "Connectivity")

    public override init() {
        super.init()
    }

    public func activate() {
        #if canImport(WatchConnectivity)
            guard WCSession.isSupported() else { return }
            WCSession.default.delegate = self
            WCSession.default.activate()
        #endif
    }

    public func send(_ n: Message) {
        #if canImport(WatchConnectivity)
            let s = WCSession.default
            guard s.activationState == .activated, let content = try? n.encoded() else { return }
            #if os(iOS)
                guard s.isPaired, s.isWatchAppInstalled else { return }
            #endif
            switch n {
            case .templates, .settings:
                // The context keeps only the newest state per key; store the two separately.
                var context = s.applicationContext
                context[Self.contextKey(n)] = content[Message.key]
                try? s.updateApplicationContext(context)
            case .run, .values:
                if s.isReachable {
                    s.sendMessage(
                        content, replyHandler: nil, errorHandler: Self.errorLogger(log, "Message"))
                } else {
                    s.transferUserInfo(content)
                }
            }
        #endif
    }

    /// Wakes the watch app for a workout started on the iPhone.
    public func wakeWatch() {
        #if os(iOS)
            guard WCSession.isSupported(), WCSession.default.isPaired, WCSession.default.isWatchAppInstalled
            else { return }
            let config = HKWorkoutConfiguration()
            config.activityType = .highIntensityIntervalTraining
            config.locationType = .indoor
            HKHealthStore().startWatchApp(with: config, completion: Self.wakeLogger(log))
        #endif
    }

    /// Builds callbacks for WatchConnectivity and HealthKit outside the main actor.
    ///
    /// A closure created in this `@MainActor` class counts as main-thread code; the system, however,
    /// calls it on its own queue, and Swift 6 then aborts with `dispatch_assert_queue` (crash when
    /// sending without a reachable watch).
    nonisolated static func errorLogger(_ log: Logger, _ was: String) -> @Sendable (Error) -> Void {
        { error in log.error("\(was, privacy: .public): \(error.localizedDescription, privacy: .public)") }
    }

    nonisolated static func wakeLogger(_ log: Logger) -> @Sendable (Bool, Error?) -> Void {
        { _, error in
            if let error { log.error("Waking watch: \(error.localizedDescription, privacy: .public)") }
        }
    }

    nonisolated static func contextKey(_ n: Message) -> String {
        if case .templates = n { "vorlagen" } else { "einstellungen" }
    }

    fileprivate func receive(_ content: [String: Data]) {
        if let n = Message.decoded(content) { onReceive?(n) }
    }

    fileprivate func receiveContext(_ context: [String: Data]) {
        for data in context.values {
            if let n = try? JSONDecoder().decode(Message.self, from: data) {
                onReceive?(n)
            }
        }
    }
}

#if canImport(WatchConnectivity)
    extension WatchLink: WCSessionDelegate {
        nonisolated public func session(
            _ session: WCSession, activationDidCompleteWith state: WCSessionActivationState, error: Error?
        ) {
            let context = Self.dataValues(session.receivedApplicationContext)
            Task { @MainActor in
                self.receiveContext(context)
                self.onConnected?()
            }
        }

        nonisolated public func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
            let d = Self.dataValues(message)
            Task { @MainActor in self.receive(d) }
        }

        nonisolated public func session(
            _ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]
        ) {
            let d = Self.dataValues(userInfo)
            Task { @MainActor in self.receive(d) }
        }

        nonisolated public func session(
            _ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]
        ) {
            let d = Self.dataValues(applicationContext)
            Task { @MainActor in self.receiveContext(d) }
        }

        nonisolated public func sessionReachabilityDidChange(_ session: WCSession) {
            guard session.isReachable else { return }
            Task { @MainActor in self.onConnected?() }
        }

        #if os(iOS)
            nonisolated public func sessionDidBecomeInactive(_ session: WCSession) {}
            nonisolated public func sessionDidDeactivate(_ session: WCSession) {
                session.activate()
            }
        #endif

        /// `[String: Any]` is not Sendable; only the data values cross the boundary.
        nonisolated static func dataValues(_ content: [String: Any]) -> [String: Data] {
            content.compactMapValues { $0 as? Data }
        }
    }
#endif
