import Core
import Design
import SwiftUI

/// Summary screen: after the last circuit or after "End".
struct SummaryScreen: View {
    @Environment(AppModel.self) private var model
    let summary: WorkoutSummary

    @Environment(\.isLandscape) private var landscape

    var body: some View {
        Group {
            if landscape {
                HStack(spacing: 28) {
                    header.frame(maxHeight: .infinity)
                    VStack(alignment: .leading, spacing: 0) {
                        tiles
                        hint
                        Spacer(minLength: 0)
                        buttons
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    Spacer()
                    header
                    Spacer()
                    tiles
                    hint
                    buttons.padding(.top, 18)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Palette.background)
        .foregroundStyle(Palette.text)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(verbatim: summary.template).fontRole(.label).allCaps().foregroundStyle(Palette.muted)
            Text(app: "summary.done").fontRole(.digits(104)).allCaps().foregroundStyle(Palette.green)
                .lineLimit(1).minimumScaleFactor(0.5)
                .accessibilityAddTraits(.isHeader)
        }
    }

    private var tiles: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible())], spacing: 10) {
            tile("summary.time", TimeFormat.short(summary.duration))
            tile("summary.rounds", "\(summary.rounds)")
            if let k = summary.calories { tile("summary.calories", "\(k)") }
            if let p = summary.heartRate { tile("summary.heartRate", "\(p)", color: Palette.heartRate) }
        }
    }

    private var hint: some View {
        Text(app: summary.calories == nil ? "summary.noWatch" : "summary.hint")
            .fontRole(.small).foregroundStyle(Palette.muted)
            .padding(.top, 10)
    }

    private var buttons: some View {
        HStack(spacing: 10) {
            Button {
                model.training.close()
            } label: {
                Text(app: "button.close").fontRole(.button).allCaps()
                    .frame(width: 140, height: landscape ? 60 : 72)
                    .background(Palette.button, in: Capsule())
            }
            Button {
                if let v = model.store.selected { model.start(v) }
            } label: {
                Text(app: "button.again").fontRole(.button).allCaps()
                    .frame(maxWidth: .infinity, minHeight: landscape ? 60 : 72)
                    .foregroundStyle(Palette.ink)
                    .background(Palette.green, in: Capsule())
            }
        }
        .buttonStyle(.plain)
    }

    private func tile(_ title: LocalizedStringKey, _ value: String, color: Color = Palette.text) -> some View
    {
        VStack(alignment: .leading, spacing: 4) {
            Text(app: title).fontRole(.label).allCaps().foregroundStyle(Palette.muted)
            Text(verbatim: value).fontRole(.digits(48)).foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16).padding(.vertical, 14)
        .background(Palette.card, in: RoundedRectangle(cornerRadius: 18))
        .accessibilityElement(children: .combine)
    }
}
