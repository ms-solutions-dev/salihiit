import Core
import Design
import SwiftUI

/// Start screen: templates with sequence bar, selection, start.
///
/// Editing and deleting sit behind a swipe to the left; a one-time tip announces it. A second tap
/// still opens the editor, a long press additionally offers duplicate. In landscape two columns:
/// the list on the left, the selected template with start on the right.
struct IntervalScreen: View {
    @Environment(AppModel.self) private var model
    @Environment(\.isLandscape) private var landscape
    @AppStorage("tippWischenGesehen") private var tipSeen = false
    @State private var edited: Template?
    @State private var pendingDelete: Template?

    var body: some View {
        Group {
            if landscape {
                HStack(alignment: .top, spacing: 22) {
                    VStack(spacing: 0) {
                        PageHeader(title: "tab.interval").padding(.horizontal, 20)
                        list
                    }
                    VStack(spacing: 12) {
                        if let v = model.store.selected { selectionCard(v) }
                        Spacer(minLength: 0)
                        buttons(height: 60)
                        LandscapeBar()
                    }
                    .frame(width: 300)
                    .padding(.top, 10)
                    .padding(.trailing, 20)
                    .padding(.bottom, 8)
                }
            } else {
                VStack(spacing: 0) {
                    PageHeader(title: "tab.interval").padding(.horizontal, 20)
                    list
                    buttons(height: 72)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 14)
                }
            }
        }
        .sheet(item: $edited) { v in
            TemplateEditor(template: v, isNew: !model.store.templates.contains { $0.id == v.id })
        }
        #if DEBUG
            // For screenshots: `SIMCTL_CHILD_SALIHIIT_SCREEN=editor xcrun simctl launch …`
            .onAppear {
                switch ProcessInfo.processInfo.environment["SALIHIIT_SCREEN"] {
                case "editor": edited = model.store.selected
                case "run":
                    if let v = model.store.selected { model.start(v, at: .now.addingTimeInterval(-12)) }
                case "rest":
                    if let v = model.store.selected { model.start(v, at: .now.addingTimeInterval(-37)) }
                case "preparation":
                    if let v = model.store.selected { model.start(v, at: .now.addingTimeInterval(-1)) }
                case "paused":
                    if let v = model.store.selected {
                        model.start(v, at: .now.addingTimeInterval(-12))
                        model.training.perform(.pause)
                    }
                case "summary":
                    if let v = model.store.selected {
                        model.start(v, at: .now.addingTimeInterval(-200))
                        model.training.end()
                    }
                default: break
                }
            }
        #endif
        .confirmationDialog(
            Text(app: "template.delete.confirm"),
            isPresented: Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } }),
            titleVisibility: .visible
        ) {
            Button(role: .destructive) {
                if let v = pendingDelete { model.store.delete(v.id) }
            } label: {
                Text(app: "menu.delete")
            }
        }
    }

    private var list: some View {
        List {
            if !tipSeen && model.store.templates.count > 0 {
                tip.row()
            }
            ForEach(model.store.templates) { v in
                TemplateCard(template: v, selected: v.id == model.store.selected?.id, compact: landscape)
                    .onTapGesture {
                        // A second tap opens the editor, the first only selects.
                        if v.id == model.store.selected?.id {
                            edited = v
                        } else {
                            model.store.selection = v.id
                        }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button {
                            tipSeen = true
                            pendingDelete = v
                        } label: {
                            Label {
                                Text(app: "menu.delete")
                            } icon: {
                                Image(systemName: "trash")
                            }
                        }
                        .tint(Palette.red)
                        Button {
                            tipSeen = true
                            edited = v
                        } label: {
                            Label {
                                Text(app: "menu.edit")
                            } icon: {
                                Image(systemName: "pencil")
                            }
                        }
                        .tint(Palette.blue)
                    }
                    .contextMenu { menu(v) }
                    .row()
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .contentMargins(.vertical, 10, for: .scrollContent)
    }

    private var tip: some View {
        HStack(spacing: 10) {
            Image(systemName: "hand.draw").foregroundStyle(Palette.green)
            Text(app: "tip.swipe").fontRole(.small).foregroundStyle(Palette.muted)
            Spacer(minLength: 0)
            Button {
                withAnimation { tipSeen = true }
            } label: {
                Image(systemName: "xmark").font(.footnote.weight(.bold)).foregroundStyle(Palette.muted)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(app: "tip.close"))
        }
        .padding(.leading, 14)
        .background(Palette.card.opacity(0.6), in: RoundedRectangle(cornerRadius: 14))
    }

    @ViewBuilder private func menu(_ v: Template) -> some View {
        Button {
            edited = v
        } label: {
            Label {
                Text(app: "menu.edit")
            } icon: {
                Image(systemName: "pencil")
            }
        }
        Button {
            model.store.duplicate(v.id, nameSuffix: localized("template.copy"))
        } label: {
            Label {
                Text(app: "menu.duplicate")
            } icon: {
                Image(systemName: "plus.square.on.square")
            }
        }
        Button(role: .destructive) {
            pendingDelete = v
        } label: {
            Label {
                Text(app: "menu.delete")
            } icon: {
                Image(systemName: "trash")
            }
        }
    }

    /// Landscape, right: the selected template with its sequence and edit.
    private func selectionCard(_ v: Template) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            TemplateCard(template: v, selected: false)
            Button {
                edited = v
            } label: {
                Label {
                    Text(app: "menu.edit").fontRole(.label).allCaps()
                } icon: {
                    Image(systemName: "pencil")
                }
                .frame(maxWidth: .infinity, minHeight: 44)
                .overlay(Capsule().stroke(Palette.line, lineWidth: 2))
                .contentShape(Capsule())
            }
            .buttonStyle(.plain)
        }
    }

    private func buttons(height: CGFloat) -> some View {
        HStack(spacing: 10) {
            Button {
                edited = Template(name: localized("template.new"), active: 30, rest: 15, rounds: 4)
            } label: {
                Image(systemName: "plus")
                    .font(.title2.weight(.semibold))
                    .frame(width: height, height: height)
                    .overlay(Circle().stroke(Palette.line, lineWidth: 2))
                    .contentShape(Circle())
            }
            .accessibilityLabel(Text(app: "button.new"))
            Button {
                if let v = model.store.selected { model.start(v) }
            } label: {
                Text(app: "button.start").fontRole(.button).allCaps()
                    .frame(maxWidth: .infinity, minHeight: height)
                    .foregroundStyle(Palette.ink)
                    .background(Palette.green, in: Capsule())
            }
            .disabled(model.store.selected == nil)
        }
        .buttonStyle(.plain)
    }
}

extension View {
    /// A list row without the system frame, spaced like the former card list.
    fileprivate func row() -> some View {
        listRowInsets(EdgeInsets(top: 5, leading: 20, bottom: 5, trailing: 20))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
    }
}

/// A template in the list.
struct TemplateCard: View {
    let template: Template
    let selected: Bool
    /// In landscape without sequence bar and blurb; the selection on the right shows them.
    var compact = false

    var body: some View {
        let plan = PhasePlan(template)
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(verbatim: template.name).fontRole(.card).allCaps().lineLimit(1)
                Spacer()
                Text(verbatim: TimeFormat.short(plan.total)).fontRole(.card)
            }
            if !compact {
                SequenceBar(plan: plan)
                Text(verbatim: Blurb.short(template)).fontRole(.small).foregroundStyle(Palette.muted)
            }
        }
        .padding(compact ? 10 : 14)
        .background(Palette.card, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(selected ? Palette.green : .clear, lineWidth: 3))
        .contentShape(RoundedRectangle(cornerRadius: 18))
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
    }
}

/// "30 s / 15 s · 4 rounds · 3 circuits"
enum Blurb {
    static func short(_ v: Template) -> String {
        var parts = ["\(v.active) s / \(v.rest) s", localized("template.rounds \(v.rounds)")]
        if v.circuits > 1 { parts.append(localized("template.circuits \(v.circuits)")) }
        return parts.joined(separator: " · ")
    }
}
