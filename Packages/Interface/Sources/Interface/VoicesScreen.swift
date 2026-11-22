import Design
import Signals
import Storage
import SwiftUI

/// Settings › Sounds & voices: everything that sounds, with a preview for each entry.
///
/// The trainer wants to hear how it sounds before playing it to their group, so each row has a
/// preview button and does not select on tap. The countdown asks three things one below the other:
/// whether, how many, who. Choosing a voice no longer sets the length to 5 by itself.
struct VoicesScreen: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var back

    /// Voices in the device language come first.
    private static var language: String { String(Locale.preferredLanguages.first?.prefix(2) ?? "en") }

    var body: some View {
        @Bindable var e = model.settings
        let isOn = e.values.isCountdownOn
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HeaderBar(leading: .init(title: "button.back") { back() })
                Text(app: "settings.soundsVoices").fontRole(.title).allCaps()
                    .accessibilityAddTraits(.isHeader)

                FormGroup {
                    ToggleRow(title: "voices.countLast", value: $e.values.isCountdownOn)
                }

                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(app: "voices.howMany").fontRole(.label).allCaps().foregroundStyle(Palette.muted)
                            .padding(.horizontal, 4)
                            .accessibilityAddTraits(.isHeader)
                        LengthPicker(value: e.values.countdownLength) { e.values.setLength($0) }
                    }

                    FormGroup(title: "voices.whoCounts") {
                        ChoiceRow(
                            title: Text(app: "voices.sound \(e.values.soundSet.name)"),
                            selected: e.values.coach == nil
                        ) {
                            e.values.coach = nil
                        } onPreview: {
                            model.training.signals.preview(e.values.soundSet, count: e.values.countdownLength)
                        }
                        ForEach(CoachVoice.ordered(CoachVoice.all, for: Self.language)) { s in
                            RowSeparator()
                            ChoiceRow(
                                title: Text(verbatim: s.name), subtitle: s.localizedSubtitle,
                                selected: e.values.coach == s.id
                            ) {
                                e.values.coach = s.id
                            } onPreview: {
                                model.training.signals.preview(
                                    coach: s.id, soundSet: e.values.soundSet, count: e.values.countdownLength)
                            }
                        }
                    }
                }
                .disabled(!isOn)
                .opacity(isOn ? 1 : 0.4)
                .animation(.snappy(duration: 0.2), value: isOn)

                FormGroup(title: "voices.phaseSound") {
                    ForEach(Array(SoundSet.allCases.enumerated()), id: \.element) { i, t in
                        if i > 0 { RowSeparator() }
                        ChoiceRow(title: Text(app: t.title), selected: e.values.soundSet == t) {
                            e.values.soundSet = t
                        } onPreview: {
                            model.training.signals.preview(t, count: 0)
                        }
                    }
                }

                FormGroup(footer: "voices.announce.hint") {
                    ToggleRow(title: "voices.announce", value: $e.values.voice)
                }

                if !CoachVoice.all.isEmpty {
                    Text(app: "voices.source").fontRole(.small).foregroundStyle(Palette.muted)
                        .padding(.horizontal, 4)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
        .background(Palette.background)
        .toolbar(.hidden, for: .navigationBar)
    }
}

/// "Last 3 / Last 5" as a segment in the app style.
private struct LengthPicker: View {
    let value: Int
    let select: (Int) -> Void

    var body: some View {
        HStack(spacing: 4) {
            ForEach([3, 5], id: \.self) { n in
                Button {
                    select(n)
                } label: {
                    Text(app: "voices.last \(n)").fontRole(.label).allCaps()
                        .foregroundStyle(value == n ? Palette.ink : Palette.muted)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(
                            value == n ? Palette.text : .clear, in: RoundedRectangle(cornerRadius: 11)
                        )
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(value == n ? .isSelected : [])
            }
        }
        .padding(4)
        .background(Palette.card, in: RoundedRectangle(cornerRadius: 14))
    }
}
