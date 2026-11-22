import SwiftUI

extension Text {
    /// A localized text from the app catalog (`App/Resources/Localizable.xcstrings`).
    ///
    /// Inside a package, `Text("key")` looks in the package bundle and silently shows the bare key.
    /// That is why all UI text goes through here; the strings check validates every key against the catalog.
    public init(app key: LocalizedStringKey) {
        self.init(key, bundle: .main)
    }
}

/// A localized text as a `String`, for example for announcements and accessibility.
public func localized(_ key: String.LocalizationValue) -> String {
    String(localized: key, bundle: .main)
}
