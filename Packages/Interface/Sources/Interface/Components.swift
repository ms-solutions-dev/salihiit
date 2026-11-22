import Design
import SwiftUI

/// Header of the sub-screens in the app style: text buttons in Barlow Condensed instead of the
/// system's glass buttons, which looked foreign next to the rest of the app.
struct HeaderBar: View {
    struct Item {
        let title: LocalizedStringKey
        var highlighted = false
        var isDisabled = false
        let action: () -> Void
    }

    var leading: Item?
    var trailing: Item?

    var body: some View {
        HStack {
            if let leading { button(leading) }
            Spacer()
            if let trailing { button(trailing) }
        }
        .frame(minHeight: 44)
    }

    private func button(_ k: Item) -> some View {
        Button(action: k.action) {
            Text(app: k.title).fontRole(.label).allCaps()
                .foregroundStyle(k.highlighted ? Palette.green : Palette.muted)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(k.isDisabled)
        .opacity(k.isDisabled ? 0.4 : 1)
    }
}

/// A group of rows with a heading and a footnote, as in the editor.
struct FormGroup<Content: View>: View {
    var title: LocalizedStringKey?
    var footer: LocalizedStringKey?
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title {
                Text(app: title).fontRole(.label).allCaps().foregroundStyle(Palette.muted)
                    .padding(.horizontal, 4)
                    .accessibilityAddTraits(.isHeader)
            }
            VStack(spacing: 0) { content }
                .background(Palette.card, in: RoundedRectangle(cornerRadius: 18))
            if let footer {
                Text(app: footer).fontRole(.small).foregroundStyle(Palette.muted).padding(.horizontal, 4)
            }
        }
    }
}

/// The separator line between two rows of a group.
struct RowSeparator: View {
    var body: some View {
        Rectangle().fill(Palette.line.opacity(0.6)).frame(height: 1).padding(.leading, 16)
    }
}

/// A row with a switch; title in capitals as in the editor.
struct ToggleRow: View {
    let title: LocalizedStringKey
    @Binding var value: Bool

    var body: some View {
        Toggle(isOn: $value) {
            Text(app: title).fontRole(.label).allCaps()
        }
        .toggleStyle(GreenToggleStyle())
        .padding(.horizontal, 16)
        .frame(minHeight: 56)
    }
}

/// The app's switch: green with a dark knob, gray when off.
struct GreenToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack {
                configuration.label
                Spacer(minLength: 12)
                Capsule()
                    .fill(configuration.isOn ? Palette.green : Palette.button)
                    .frame(width: 56, height: 32)
                    .overlay(alignment: configuration.isOn ? .trailing : .leading) {
                        Circle()
                            .fill(configuration.isOn ? Palette.ink : Palette.muted)
                            .frame(width: 26, height: 26)
                            .padding(3)
                    }
                    .animation(.snappy(duration: 0.2), value: configuration.isOn)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityRepresentation {
            Toggle(isOn: configuration.$isOn) { configuration.label }
        }
    }
}

/// The button for previewing (sounds and voices).
struct PreviewButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "play.fill")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Palette.ink)
                .frame(width: 36, height: 36)
                .background(Palette.green, in: Circle())
                .frame(minWidth: 44, minHeight: 44)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(app: "voices.preview"))
    }
}

/// A choice row: tapping selects, the button on the right plays a preview.
struct ChoiceRow: View {
    let title: Text
    var subtitle: String?
    let selected: Bool
    let select: () -> Void
    var onPreview: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            Button(action: select) {
                HStack(spacing: 12) {
                    Circle()
                        .strokeBorder(selected ? Palette.green : Palette.muted, lineWidth: selected ? 7 : 2)
                        .frame(width: 22, height: 22)
                    VStack(alignment: .leading, spacing: 2) {
                        title.fontRole(.label).allCaps()
                        if let subtitle {
                            Text(verbatim: subtitle).fontRole(.small).foregroundStyle(Palette.muted)
                        }
                    }
                    Spacer(minLength: 0)
                }
                .frame(minHeight: 56)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(selected ? .isSelected : [])
            if let onPreview { PreviewButton(action: onPreview) }
        }
        .padding(.leading, 16)
        .padding(.trailing, 8)
    }
}

/// Page header of the three modes with settings on the right.
struct PageHeader: View {
    @Environment(AppModel.self) private var model
    let title: LocalizedStringKey

    var body: some View {
        HStack {
            Text(app: title).fontRole(.title).allCaps()
                .accessibilityAddTraits(.isHeader)
            Spacer()
            Button {
                model.isSettingsOpen = true
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.title3)
                    .frame(width: 44, height: 44)
                    .foregroundStyle(Palette.muted)
            }
            .accessibilityLabel(Text(app: "button.settings"))
        }
    }
}

extension EnvironmentValues {
    /// True in landscape on an iPhone (compact height).
    var isLandscape: Bool { verticalSizeClass == .compact }
}
