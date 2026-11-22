import CoreText
import SwiftUI

/// Font roles: Barlow Condensed for digits and headings, Barlow for body text.
///
/// Static cuts instead of `.weight()`, because SwiftUI silently falls back to the nearest available
/// cut for custom fonts. All roles except the large digits scale with Dynamic Type.
public enum FontRole {
    case title
    case card
    case button
    case label
    case bodyText
    case small
    /// The large digits; the size comes from the available space, not from Dynamic Type.
    case digits(CGFloat)

    var font: Font {
        switch self {
        case .title: .custom("BarlowCondensed-ExtraBold", size: 40, relativeTo: .largeTitle)
        case .card: .custom("BarlowCondensed-Bold", size: 28, relativeTo: .title)
        case .button: .custom("BarlowCondensed-ExtraBold", size: 28, relativeTo: .title2)
        case .label: .custom("BarlowCondensed-Bold", size: 20, relativeTo: .headline)
        case .bodyText: .custom("Barlow-Regular", size: 17, relativeTo: .body)
        case .small: .custom("Barlow-Medium", size: 14, relativeTo: .footnote)
        case .digits(let size): .custom("BarlowCondensed-ExtraBold", fixedSize: size)
        }
    }

    /// Registers the bundled fonts with the system. Once at launch, idempotent.
    @MainActor public static func register() {
        guard !registered else { return }
        registered = true
        guard let folder = Bundle.module.url(forResource: "Fonts", withExtension: nil),
            let files = try? FileManager.default.contentsOfDirectory(
                at: folder, includingPropertiesForKeys: nil)
        else { return }
        for url in files where url.pathExtension == "ttf" {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }

    @MainActor private static var registered = false
}

extension View {
    /// Applies a font role; digits are tabular so nothing jumps.
    public func fontRole(_ role: FontRole) -> some View {
        font(role.font).monospacedDigit()
    }

    /// Uppercase, for labels and buttons.
    public func allCaps() -> some View {
        textCase(.uppercase)
    }
}
