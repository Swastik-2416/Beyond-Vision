import Foundation

struct FeedbackEntry: Identifiable, Codable, Equatable {
    var id = UUID()
    var type: String
    var message: String
    var date: Date
}

/// Stores user feedback locally as JSON in the app's Documents directory, so
/// submissions persist across launches even with no network or backend.
@MainActor
final class FeedbackStore: ObservableObject {
    @Published private(set) var entries: [FeedbackEntry] = []

    private let fileURL: URL = {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("feedback.json")
    }()

    init() {
        load()
    }

    func add(type: String, message: String) {
        let entry = FeedbackEntry(type: type,
                                  message: message.trimmingCharacters(in: .whitespacesAndNewlines),
                                  date: Date())
        entries.insert(entry, at: 0)
        save()
    }

    func delete(_ entry: FeedbackEntry) {
        entries.removeAll { $0.id == entry.id }
        save()
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([FeedbackEntry].self, from: data) else { return }
        entries = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
