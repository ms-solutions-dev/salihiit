import Design
import Signals
import Storage
import SwiftUI
import UIKit

/// Settings screen, entirely in the app style.
struct SettingsScreen: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var close
    @Environment(\.openURL) private var open
    @State private var path: [String] = []

    var body: some View {
        @Bindable var e = model.settings
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    HeaderBar(trailing: .init(title: "button.done", highlighted: true) { close() })
                    Text(app: "button.settings").fontRole(.title).allCaps()
                        .accessibilityAddTraits(.isHeader)

                    FormGroup(title: "settings.signals") {
                        NavigationLink(value: "voices") {
                            HStack {
                                Text(app: "settings.soundsVoices").fontRole(.label).allCaps()
                                Spacer()
                                Text(verbatim: summaryText(e.values)).fontRole(.label).allCaps()
                                    .foregroundStyle(Palette.green).lineLimit(1)
                                Image(systemName: "chevron.right").foregroundStyle(Palette.muted)
                            }
                            .padding(.horizontal, 16)
                            .frame(minHeight: 56)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        RowSeparator()
                        ToggleRow(title: "settings.vibration", value: $e.values.vibration)
                    }

                    FormGroup(title: "settings.workout", footer: "settings.health.hint") {
                        ToggleRow(title: "settings.music", value: $e.values.lowerMusic)
                        RowSeparator()
                        ToggleRow(title: "settings.screenOn", value: $e.values.keepScreenOn)
                        RowSeparator()
                        ToggleRow(title: "settings.health", value: $e.values.health)
                    }

                    FormGroup(title: "settings.icon") {
                        LazyVGrid(
                            columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 3),
                            spacing: 18
                        ) {
                            ForEach(AppIcon.allCases, id: \.self) { s in
                                iconChoice(s, selected: e.values.icon == s) {
                                    e.values.icon = s
                                    UIApplication.shared.setAlternateIconName(s.iconSetName)
                                }
                            }
                        }
                        .padding(.vertical, 16)
                    }

                    FormGroup {
                        Button {
                            if let url = URL(string: UIApplication.openSettingsURLString) { open(url) }
                        } label: {
                            HStack {
                                Text(app: "settings.language.change").fontRole(.label).allCaps()
                                Spacer()
                                Image(systemName: "arrow.up.right").foregroundStyle(Palette.muted)
                            }
                            .padding(.horizontal, 16)
                            .frame(minHeight: 56)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(app: "settings.language")
                        Text(app: "settings.version \(Self.version)")
                    }
                    .fontRole(.small).foregroundStyle(Palette.muted).padding(.horizontal, 4)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
            .background(Palette.background)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: String.self) { _ in VoicesScreen() }
            #if DEBUG
                .onAppear {
                    if ProcessInfo.processInfo.environment["SALIHIIT_SCREEN"] == "voices" {
                        path = ["voices"]
                    }
                }
            #endif
        }
        .foregroundStyle(Palette.text)
        .tint(Palette.green)
        .preferredColorScheme(.dark)
    }

    /// "Whistle · Charlie" in the sounds and voices row.
    private func summaryText(_ e: Settings) -> String {
        let sound = e.soundSet.name
        guard e.isCountdownOn else { return sound }
        return [sound, e.coach.flatMap { id in CoachVoice.all.first { $0.id == id }?.name }]
            .compactMap { $0 }.joined(separator: " · ")
    }

    private func iconChoice(_ s: AppIcon, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(s.preview)
                    .resizable()
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(selected ? Palette.text : .clear, lineWidth: 3)
                            .padding(-4)
                    )
                Text(app: s.title).fontRole(.small).allCaps()
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    static var version: String {
        let i = Bundle.main.infoDictionary
        return
            "\(i?["CFBundleShortVersionString"] as? String ?? "?") (\(i?["CFBundleVersion"] as? String ?? "?"))"
    }
}

extension SoundSet {
    var title: LocalizedStringKey {
        switch self {
        case .whistle: "sound.whistle"
        case .bell: "sound.bell"
        case .gong: "sound.gong"
        case .digital: "sound.digital"
        case .beep: "sound.beep"
        }
    }

    var name: String {
        switch self {
        case .whistle: localized("sound.whistle")
        case .bell: localized("sound.bell")
        case .gong: localized("sound.gong")
        case .digital: localized("sound.digital")
        case .beep: localized("sound.beep")
        }
    }
}

extension AppIcon {
    var title: LocalizedStringKey {
        switch self {
        case .wordmark: "icon.wordmark"
        case .ring: "icon.ring"
        case .stopwatch: "icon.stopwatch"
        case .monogram: "icon.monogram"
        case .pulse: "icon.pulse"
        case .dark: "icon.dark"
        }
    }
}
