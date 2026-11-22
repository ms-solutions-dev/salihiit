import Core
import Foundation
import Observation

/// The templates as a JSON file in the App Group.
///
/// No SwiftData: there are only a handful of entries, and the sync with the watch sends exactly
/// this list. A single file cannot end up half-migrated.
@MainActor @Observable public final class TemplateStore {
    public private(set) var templates: [Template]
    /// The template started or tapped last. Stays per device and is not sent to the watch.
    public var selection: UUID? {
        didSet { write() }
    }

    private let file: URL
    /// Reports every change, for example to the watch link.
    @ObservationIgnored public var onChange: (([Template]) -> Void)?

    /// - Parameters:
    ///   - folder: Defaults to the App Group container; tests pass their own folder.
    ///   - samples: What the list contains on first launch, with translated names.
    public init(folder: URL? = nil, samples: [Template] = Template.samples) {
        let base =
            folder
            ?? FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Identifiers.appGroup)
            ?? URL.applicationSupportDirectory
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        file = base.appending(path: "vorlagen.json")
        if let data = try? Data(contentsOf: file),
            let loaded = try? JSONDecoder().decode(StoreFile.self, from: data)
        {
            templates = loaded.templates
            selection = loaded.selection
        } else {
            templates = samples
            selection = samples.first?.id
        }
    }

    public var selected: Template? {
        templates.first { $0.id == selection } ?? templates.first
    }

    /// Adds or replaces (same `id`).
    public func save(_ template: Template) {
        if let i = templates.firstIndex(where: { $0.id == template.id }) {
            templates[i] = template
        } else {
            templates.append(template)
        }
        selection = template.id
        commit()
    }

    public func delete(_ id: UUID) {
        templates.removeAll { $0.id == id }
        if selection == id { selection = templates.first?.id }
        commit()
    }

    public func duplicate(_ id: UUID, nameSuffix: String) {
        guard var copy = templates.first(where: { $0.id == id }) else { return }
        copy.id = UUID()
        copy.name += " " + nameSuffix
        save(copy)
    }

    public func move(from source: IndexSet, to target: Int) {
        // `move(fromOffsets:)` comes from SwiftUI; the store stays free of UI frameworks.
        let moved = source.map { templates[$0] }
        let before = source.filter { $0 < target }.count
        for i in source.reversed() { templates.remove(at: i) }
        templates.insert(contentsOf: moved, at: target - before)
        commit()
    }

    /// Renames sample templates whose name still matches one of the bundled translations to the
    /// current language. The samples are stored in the language of the first launch; if the language
    /// changed afterwards, a Turkish name could show up in the German list. Templates the user renamed
    /// themselves are left alone.
    public func syncSampleNames(_ names: [(all: Set<String>, now: String)]) {
        var onChange = false
        for i in templates.indices {
            guard let n = names.first(where: { $0.all.contains(templates[i].name) }),
                templates[i].name != n.now
            else { continue }
            templates[i].name = n.now
            onChange = true
        }
        if onChange { write() }
    }

    /// Adopts the list from the other device without reporting it back.
    public func adopt(_ list: [Template]) {
        guard list != templates else { return }
        templates = list
        if !list.contains(where: { $0.id == selection }) { selection = list.first?.id }
        write()
    }

    private func commit() {
        write()
        onChange?(templates)
    }

    private func write() {
        guard let data = try? JSONEncoder().encode(StoreFile(templates: templates, selection: selection))
        else {
            return
        }
        try? data.write(to: file, options: .atomic)
    }

    private struct StoreFile: Codable {
        var templates: [Template]
        var selection: UUID?

        private enum CodingKeys: String, CodingKey {
            case templates = "vorlagen"
            case selection = "auswahl"
        }
    }
}
