import Foundation

/// Identifiers that app, watch and widget must spell identically.
public enum Identifiers {
    public static let appGroup = "group.dev.ms-solutions.salihiit"
    public static let bundle = "dev.ms-solutions.salihiit"
}

/// The kind of a phase; determines color, announcement and signal.
public enum PhaseKind: String, Codable, Sendable, CaseIterable {
    /// Yellow: about to start.
    case preparation = "vorbereitung"
    /// Green.
    case active = "aktiv"
    /// Red, between two rounds.
    case rest = "pause"
    /// Red, between two circuits.
    case circuitRest = "zirkelpause"
    /// Blue, after the last circuit.
    case cooldown = "auslaufen"
}
