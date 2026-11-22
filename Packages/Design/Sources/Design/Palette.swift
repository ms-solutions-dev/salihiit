import Core
import SwiftUI

/// All colors of the app. Views use only these roles; a build check reports color values outside this package.
public enum Palette {
    /// Yellow: preparation.
    public static let yellow = Color(red: 1.0, green: 0.882, blue: 0.302)
    /// Green: work, main accent.
    public static let green = Color(red: 0.776, green: 1.0, blue: 0.302)
    /// Red: rest.
    public static let red = Color(red: 1.0, green: 0.302, blue: 0.239)
    /// Blue: laps and cooldown.
    public static let blue = Color(red: 0.435, green: 0.714, blue: 1.0)
    /// Heart rate on a dark background.
    public static let heartRate = Color(red: 1.0, green: 0.42, blue: 0.361)

    /// Background of all dark surfaces.
    public static let background = Color(red: 0.067, green: 0.067, blue: 0.067)
    /// Cards and lists on the background.
    public static let card = Color(red: 0.118, green: 0.118, blue: 0.118)
    /// Round secondary buttons.
    public static let button = Color(red: 0.165, green: 0.165, blue: 0.165)
    /// Separator lines and borders.
    public static let line = Color(red: 0.227, green: 0.227, blue: 0.227)
    /// Text on a dark background.
    public static let text = Color.white
    /// Secondary text on a dark background (contrast 10:1 on `background`).
    public static let muted = Color(red: 0.741, green: 0.741, blue: 0.741)
    /// Text on the bright phase surfaces.
    public static let ink = Color(red: 0.067, green: 0.067, blue: 0.067)
    /// Track of the progress bars on a phase surface.
    public static let track = Color(red: 0.067, green: 0.067, blue: 0.067).opacity(0.18)

    /// The fill of a phase.
    public static func fill(_ kind: PhaseKind) -> Color {
        switch kind {
        case .preparation, .circuitRest: yellow
        case .active: green
        case .rest: red
        case .cooldown: blue
        }
    }
}
