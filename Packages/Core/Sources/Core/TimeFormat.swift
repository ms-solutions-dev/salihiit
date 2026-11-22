import Foundation

/// Times as shown in the app: "0:17", "9:50", "10:05", from one hour on "1:02:05".
public enum TimeFormat {
    public static func short(_ seconds: Int) -> String {
        let s = max(0, seconds)
        let h = s / 3600
        let m = (s % 3600) / 60
        let r = s % 60
        return h > 0
            ? "\(h):" + twoDigits(m) + ":" + twoDigits(r)
            : "\(m):" + twoDigits(r)
    }

    /// Stopwatch with tenths: "3:27,4" (separator by device language).
    public static func tenths(
        _ seconds: Double, locale: Locale = .current
    ) -> (main: String, tenths: String) {
        let z = Int((max(0, seconds) * 10).rounded(.down))
        let separator = locale.decimalSeparator ?? ","
        return (short(z / 10), separator + String(z % 10))
    }

    private static func twoDigits(_ n: Int) -> String {
        n < 10 ? "0\(n)" : "\(n)"
    }
}
