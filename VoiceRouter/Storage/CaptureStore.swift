import Foundation

/// Persists capture history as JSON in the app's documents directory.
/// Never loses a capture — this is the safety net.
@MainActor
class CaptureStore: ObservableObject {
    @Published var captures: [Capture] = []

    private let fileURL: URL

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
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(captures)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("[CaptureStore] Save failed: \(error)")
        }
    }

    private func loadCaptures() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            captures = try decoder.decode([Capture].self, from: data)
        } catch {
            print("[CaptureStore] Load failed: \(error)")
        }
    }
}
