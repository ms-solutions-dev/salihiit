import Foundation

/// A signal that is due at a given workout time. `Signals` plays it; the background notifications
/// use the same list as a safety net.
public struct Event: Sendable, Hashable {
    public enum Kind: Sendable, Hashable {
        /// A phase begins.
        case phaseStart(Phase)
        /// `n` seconds left in the running phase (5 to 1; `Signals` filters how many sound).
        case countdown(Int)
        /// Halfway point of a work phase of 20 s or more.
        case halfway
        /// The workout is over.
        case finished
    }

    /// Workout time in seconds.
    public let time: Int
    public let kind: Kind

    public init(time: Int, kind: Kind) {
        self.time = time
        self.kind = kind
    }
}

extension PhasePlan {
    /// All events with `from <= time < to`, sorted.
    ///
    /// A countdown step is dropped when the phase is not longer than the step; otherwise it would
    /// coincide with the phase-start signal.
    public func events(from: Int, to: Int) -> [Event] {
        var list: [Event] = []
        for p in phases where p.end > from && p.start < to {
            list.append(Event(time: p.start, kind: .phaseStart(p)))
            if p.kind == .active, p.duration >= 20 {
                list.append(Event(time: p.start + p.duration / 2, kind: .halfway))
            }
            for n in stride(from: 5, through: 1, by: -1) where n < p.duration {
                list.append(Event(time: p.end - n, kind: .countdown(n)))
            }
        }
        if total >= from, total < to {
            list.append(Event(time: total, kind: .finished))
        }
        return list.filter { $0.time >= from && $0.time < to }.sorted { $0.time < $1.time }
    }
}
