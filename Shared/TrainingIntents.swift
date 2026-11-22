import AppIntents
import Core

// Buttons of the Live Activity. The file belongs to both app and widget: the widget needs the type for
// `Button(intent:)`, while `perform()` runs as a `LiveActivityIntent` in the app's process.

struct PauseIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "button.pause"

    @MainActor func perform() async throws -> some IntentResult {
        RemoteControl.perform?(.pause)
        return .result()
    }
}

struct ResumeIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "button.resume"

    @MainActor func perform() async throws -> some IntentResult {
        RemoteControl.perform?(.resume)
        return .result()
    }
}

struct SkipIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "button.skip"

    @MainActor func perform() async throws -> some IntentResult {
        RemoteControl.perform?(.skip)
        return .result()
    }
}
