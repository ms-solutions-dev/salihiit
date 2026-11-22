import Foundation

/// What the lock screen, Dynamic Island and the watch mirror show.
///
/// The digits count down there via `Text(timerInterval:)` until `phaseEnd`; a new state is sent
/// only on phase change, pause and skip.
public struct IslandState: Codable, Hashable, Sendable {
    public var kind: PhaseKind
    public var phaseStart: Date
    /// `nil` while paused; then `remainingSeconds` shows the frozen time.
    public var phaseEnd: Date?
    public var remainingSeconds: Int
    public var round: Int
    public var rounds: Int
    public var circuit: Int
    public var circuitTotal: Int
    public var exercise: String?
    public var nextKind: PhaseKind?
    public var nextDuration: Int
    public var finished: Bool

    private enum CodingKeys: String, CodingKey {
        case kind = "art"
        case phaseStart = "phasenBeginn"
        case phaseEnd = "phasenEnde"
        case remainingSeconds = "restSekunden"
        case round = "runde"
        case rounds = "runden"
        case circuit = "zirkel"
        case circuitTotal = "zirkelGesamt"
        case exercise = "uebung"
        case nextKind = "naechsteArt"
        case nextDuration = "naechsteDauer"
        case finished = "fertig"
    }

    public var isPaused: Bool { phaseEnd == nil && !finished }

    public init(_ run: Timekeeper, time: Date) {
        let z = run.state(time)
        let p = z.phase
        kind = p?.kind ?? .cooldown
        phaseStart = time.addingTimeInterval(-(Double(p?.duration ?? 0) - z.remaining))
        phaseEnd = run.phaseEnd(time)
        remainingSeconds = z.remainingSeconds
        round = p?.round ?? run.plan.rounds
        rounds = run.plan.rounds
        circuit = p?.circuit ?? run.plan.circuits
        circuitTotal = run.plan.circuits
        exercise = p?.kind == .active ? p?.exercise : nil
        nextKind = z.next?.kind
        nextDuration = z.next?.duration ?? 0
        finished = z.finished
    }
}

/// Commands from outside: Live Activity buttons, the watch, the island.
public enum Command: String, Codable, Sendable {
    case pause = "anhalten"
    case resume = "weiter"
    case skip = "ueberspringen"
    case end = "beenden"
}

/// The place where the app hooks in its control, so intents and the watch link can reach it
/// without knowing the UI.
@MainActor public enum RemoteControl {
    public static var perform: ((Command) -> Void)?
}

#if os(iOS)
    import ActivityKit

    public struct TrainingActivity: ActivityAttributes {
        public typealias ContentState = IslandState
        public var template: String

        private enum CodingKeys: String, CodingKey {
            case template = "vorlage"
        }

        public init(template: String) {
            self.template = template
        }
    }
#endif
