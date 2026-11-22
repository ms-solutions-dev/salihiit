import Core
import Design
import SwiftUI

/// A template value that the number wheel edits.
enum Field: String, Identifiable, CaseIterable {
    case preparation, active, rest, rounds, circuits, circuitRest, cooldown
    var id: String { rawValue }

    var path: WritableKeyPath<Template, Int> {
        switch self {
        case .preparation: \.preparation
        case .active: \.active
        case .rest: \.rest
        case .rounds: \.rounds
        case .circuits: \.circuits
        case .circuitRest: \.circuitRest
        case .cooldown: \.cooldown
        }
    }

    var isCount: Bool { self == .rounds || self == .circuits }

    var title: LocalizedStringKey {
        switch self {
        case .preparation: PhaseKind.preparation.title
        case .active: PhaseKind.active.title
        case .rest: PhaseKind.rest.title
        case .rounds: "field.rounds"
        case .circuits: "field.circuits"
        case .circuitRest: PhaseKind.circuitRest.title
        case .cooldown: PhaseKind.cooldown.title
        }
    }

    /// Minimum value; work and the counts must not be 0.
    var minimum: Int { self == .active || isCount ? 1 : 0 }

    func display(_ v: Template) -> String {
        isCount ? "\(v[keyPath: path])" : TimeFormat.short(v[keyPath: path])
    }
}

/// Editor screen: name, tiles, list, sequence, total.
struct TemplateEditor: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var close
    @State var template: Template
    let isNew: Bool
    @State private var field: Field?
    @State private var confirmDelete = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Text buttons in the app style instead of the system's glass buttons.
                    HeaderBar(
                        leading: .init(title: "button.cancel") { close() },
                        trailing: .init(
                            title: "button.save", highlighted: true,
                            isDisabled: template.name.trimmingCharacters(in: .whitespaces).isEmpty
                        ) {
                            model.store.save(template.clamped)
                            close()
                        }
                    )
                    VStack(alignment: .leading, spacing: 2) {
                        Text(app: "field.name").fontRole(.small).allCaps().foregroundStyle(Palette.muted)
                        TextField(text: $template.name) { Text(app: "field.name") }
                            .fontRole(.title)
                            .textInputAutocapitalization(.words)
                            .padding(.vertical, 6)
                        Rectangle().fill(Palette.line).frame(height: 2)
                    }

                    LazyVGrid(
                        columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible())], spacing: 10
                    ) {
                        tile(.active, background: Palette.green, fontRole: Palette.ink)
                        tile(.rest, background: Palette.red, fontRole: Palette.ink)
                        tile(.rounds, background: Palette.blue, fontRole: Palette.ink)
                        tile(.circuits, background: Palette.yellow, fontRole: Palette.ink)
                    }

                    VStack(spacing: 0) {
                        row(.preparation, dot: Palette.yellow)
                        if template.circuits > 1 {
                            Divider().overlay(Palette.line)
                            row(.circuitRest, dot: Palette.yellow)
                        }
                        Divider().overlay(Palette.line)
                        row(.cooldown, dot: Palette.blue)
                        Divider().overlay(Palette.line)
                        NavigationLink {
                            ExercisesScreen(template: $template)
                        } label: {
                            HStack {
                                Text(app: "editor.exercises").fontRole(.label).allCaps()
                                Spacer()
                                Text(app: "editor.optional").fontRole(.small).foregroundStyle(Palette.muted)
                                Image(systemName: "chevron.right").foregroundStyle(Palette.muted)
                            }
                            .padding(.horizontal, 16)
                            .frame(minHeight: 54)
                        }
                        .buttonStyle(.plain)
                    }
                    .background(Palette.card, in: RoundedRectangle(cornerRadius: 18))

                    VStack(alignment: .leading, spacing: 8) {
                        Text(app: "editor.sequence").fontRole(.small).allCaps().foregroundStyle(Palette.muted)
                        SequenceBar(plan: PhasePlan(template), height: 14)
                    }
                    .padding(.top, 8)

                    HStack(alignment: .firstTextBaseline) {
                        Text(app: "editor.total").fontRole(.label).allCaps().foregroundStyle(Palette.muted)
                        Spacer()
                        Text(verbatim: TimeFormat.short(PhasePlan(template).total)).fontRole(.digits(44))
                    }
                    .accessibilityElement(children: .combine)

                    if !isNew {
                        Button(role: .destructive) {
                            confirmDelete = true
                        } label: {
                            Text(app: "menu.delete").fontRole(.label).allCaps()
                                .frame(maxWidth: .infinity, minHeight: 52)
                                .foregroundStyle(Palette.red)
                        }
                        .padding(.top, 12)
                    }
                }
                .padding(20)
            }
            .background(Palette.background)
            .toolbar(.hidden, for: .navigationBar)
            .sheet(item: $field) { f in
                NumberPicker(field: f, value: $template[dynamicMember: f.path])
                    .presentationDetents([.height(340)])
            }
            .confirmationDialog(
                Text(app: "template.delete.confirm"), isPresented: $confirmDelete, titleVisibility: .visible
            ) {
                Button(role: .destructive) {
                    model.store.delete(template.id)
                    close()
                } label: {
                    Text(app: "menu.delete")
                }
            }
        }
        .tint(Palette.green)
        .preferredColorScheme(.dark)
    }

    private func tile(_ f: Field, background: Color, fontRole: Color) -> some View {
        Button {
            field = f
        } label: {
            VStack(alignment: .leading) {
                Text(app: f.title).fontRole(.label).allCaps().opacity(background == Palette.card ? 0.75 : 1)
                Spacer(minLength: 4)
                Text(verbatim: f.display(template)).fontRole(.digits(50))
            }
            .frame(maxWidth: .infinity, minHeight: 108, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .foregroundStyle(fontRole)
            .background(background, in: RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }

    private func row(_ f: Field, dot: Color) -> some View {
        Button {
            field = f
        } label: {
            HStack(spacing: 10) {
                Circle().fill(dot).frame(width: 10, height: 10)
                Text(app: f.title).fontRole(.label).allCaps()
                Spacer()
                Text(verbatim: f.display(template)).fontRole(.label)
            }
            .padding(.horizontal, 16)
            .frame(minHeight: 54)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }
}

/// The number wheel: minutes and seconds for times, a single column for counts.
struct NumberPicker: View {
    let field: Field
    @Binding var value: Int
    @Environment(\.dismiss) private var close

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(app: field.title).fontRole(.label).allCaps()
                Spacer()
                Button {
                    close()
                } label: {
                    Text(app: "button.done").bold()
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)

            if field.isCount {
                Picker(selection: $value) {
                    ForEach(field.minimum...Template.Limits.count, id: \.self) { n in
                        Text(verbatim: "\(n)").tag(n)
                    }
                } label: {
                    Text(app: field.title)
                }
                .pickerStyle(.wheel)
            } else {
                HStack(spacing: 0) {
                    Picker(selection: minutes) {
                        ForEach(0...99, id: \.self) { m in Text(verbatim: "\(m)").tag(m) }
                    } label: {
                        Text(app: "picker.minutes")
                    }
                    .pickerStyle(.wheel)
                    Text(app: "picker.minutes").fontRole(.small).foregroundStyle(Palette.muted)
                    Picker(selection: seconds) {
                        ForEach(0...59, id: \.self) { s in Text(verbatim: s < 10 ? "0\(s)" : "\(s)").tag(s) }
                    } label: {
                        Text(app: "picker.seconds")
                    }
                    .pickerStyle(.wheel)
                    Text(app: "picker.seconds").fontRole(.small).foregroundStyle(Palette.muted)
                }
                .padding(.horizontal, 20)
            }
        }
        .background(Palette.card)
        .preferredColorScheme(.dark)
    }

    private var minutes: Binding<Int> {
        Binding(
            get: { value / 60 },
            set: { value = max(field.minimum, min($0 * 60 + value % 60, Template.Limits.duration)) })
    }

    private var seconds: Binding<Int> {
        Binding(get: { value % 60 }, set: { value = max(field.minimum, (value / 60) * 60 + $0) })
    }
}
