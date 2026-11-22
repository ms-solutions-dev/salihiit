import Core
import Design
import SwiftUI

/// Exercises screen: optional names per round (not a required field).
struct ExercisesScreen: View {
    @Binding var template: Template
    @Environment(\.dismiss) private var back

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HeaderBar(leading: .init(title: "button.back") { back() })
                Text(app: "editor.exercises").fontRole(.title).allCaps()
                    .accessibilityAddTraits(.isHeader)
                Text(app: "exercises.hint").fontRole(.bodyText).foregroundStyle(Palette.muted)

                if template.circuits > 1 {
                    FormGroup {
                        ToggleRow(title: "exercises.same", value: $template.sameExercises)
                    }
                }

                ForEach(1...(template.sameExercises ? 1 : template.circuits), id: \.self) { z in
                    if !template.sameExercises {
                        Text(app: "exercises.circuit \(z)").fontRole(.label).allCaps().foregroundStyle(
                            Palette.muted)
                    }
                    VStack(spacing: 0) {
                        ForEach(1...template.rounds, id: \.self) { r in
                            HStack(spacing: 12) {
                                Text(app: "exercises.round \(r)").fontRole(.label).allCaps()
                                    .foregroundStyle(Palette.green)
                                    .frame(width: 80, alignment: .leading)
                                TextField(text: name(circuits: z, round: r)) { Text(app: "exercises.none") }
                                    .fontRole(.bodyText)
                                    .submitLabel(.next)
                            }
                            .padding(.horizontal, 16)
                            .frame(minHeight: 56)
                            if r < template.rounds { Divider().overlay(Palette.line) }
                        }
                    }
                    .background(Palette.card, in: RoundedRectangle(cornerRadius: 18))
                }

                Text(app: "exercises.announce").fontRole(.small).foregroundStyle(Palette.muted)
            }
            .padding(20)
        }
        .background(Palette.background)
        .toolbar(.hidden, for: .navigationBar)
    }

    /// The table grows on demand so rounds and circuits can be increased later.
    private func name(circuits z: Int, round r: Int) -> Binding<String> {
        Binding {
            let row = z - 1
            guard template.exercises.indices.contains(row), template.exercises[row].indices.contains(r - 1)
            else { return "" }
            return template.exercises[row][r - 1]
        } set: { new in
            while template.exercises.count < z { template.exercises.append([]) }
            while template.exercises[z - 1].count < r { template.exercises[z - 1].append("") }
            template.exercises[z - 1][r - 1] = new
        }
    }
}
