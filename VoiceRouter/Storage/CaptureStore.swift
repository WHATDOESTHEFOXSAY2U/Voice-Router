import Foundation

actor CapturePersistence {
    func save(_ captures: [Capture], to fileURL: URL) {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(captures)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("[CaptureStore] Save failed: \(error)")
        }
    }

    func load(from fileURL: URL) -> [Capture] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode([Capture].self, from: data)
        } catch {
            print("[CaptureStore] Load failed: \(error)")
            return []
        }
    }
}

/// Persists capture history as JSON in the app's documents directory.
/// Never loses a capture — this is the safety net.
@MainActor
class CaptureStore: ObservableObject {
    @Published var captures: [Capture] = []

    private let fileURL: URL
    private let persistence = CapturePersistence()

    init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.fileURL = docs.appendingPathComponent("captures.json")
        loadCaptures()
    }

    func addCapture(_ capture: Capture) {
        captures.insert(capture, at: 0)
        saveCaptures()
    }

    func deleteCapture(at offsets: IndexSet) {
        captures.remove(atOffsets: offsets)
        saveCaptures()
    }

    func deleteCapture(id: UUID) {
        captures.removeAll { $0.id == id }
        saveCaptures()
    }

    func updateStatus(id: UUID, status: CaptureStatus, error: String? = nil) {
        if let index = captures.firstIndex(where: { $0.id == id }) {
            captures[index].status = status
            captures[index].errorMessage = error
            saveCaptures()
        }
    }

    // MARK: - Persistence

    private func saveCaptures() {
        let snapshot = captures
        let fileURL = fileURL

        Task(priority: .utility) {
            await persistence.save(snapshot, to: fileURL)
        }
    }

    private func loadCaptures() {
        let fileURL = fileURL

        Task(priority: .utility) {
            let loadedCaptures = await persistence.load(from: fileURL)

            await MainActor.run {
                if captures.isEmpty {
                    captures = loadedCaptures
                    return
                }

                let existingIDs = Set(captures.map(\.id))
                let merged = captures + loadedCaptures.filter { !existingIDs.contains($0.id) }
                captures = merged.sorted { $0.createdAt > $1.createdAt }
            }
        }
    }
}
