import Foundation
import Observation

// MARK: - Data types

struct CompoundEntry: Decodable {
    let name: String
    let aliases: [String]
    let route: String?
    let defaultDoseUnit: String?
    let defaultHalfLifeHours: Double?
    let colorHex: String?
}

private struct CompoundLibrary: Decodable {
    let version: Int
    let compounds: [CompoundEntry]
}

// MARK: - Service

@Observable final class CompoundLibraryService {
    private(set) var suggestions: [CompoundEntry] = []
    private(set) var isLoading = false
    private(set) var fetchError: String? = nil

    private var allCompounds: [CompoundEntry] = []
    private var searchTask: Task<Void, Never>?

    private static let remoteURL = URL(string: "https://raw.githubusercontent.com/Bhamm7/doseday-compounds/main/compounds.json")!
    private static let cacheFileName = "compound_library_cache.json"
    private static let cacheTTL: TimeInterval = 86400 // 24 hours

    private var cacheURL: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
            .appendingPathComponent(Self.cacheFileName)
    }

    func load() async {
        guard allCompounds.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }

        // Check cache freshness
        if let cacheData = freshCacheData() {
            if let lib = try? JSONDecoder().decode(CompoundLibrary.self, from: cacheData) {
                allCompounds = lib.compounds
                return
            }
        }

        // Fetch remote
        do {
            let (data, _) = try await URLSession.shared.data(from: Self.remoteURL)
            if let lib = try? JSONDecoder().decode(CompoundLibrary.self, from: data) {
                allCompounds = lib.compounds
                try? data.write(to: cacheURL)
                fetchError = nil
            } else {
                loadStaleCache()
            }
        } catch {
            loadStaleCache()
        }
    }

    func search(_ query: String) {
        searchTask?.cancel()
        guard !query.isEmpty else {
            suggestions = []
            return
        }
        let q = query.lowercased()
        searchTask = Task {
            guard !Task.isCancelled else { return }
            let results = allCompounds.filter { entry in
                entry.name.lowercased().hasPrefix(q) ||
                entry.aliases.contains { $0.hasPrefix(q) }
            }.prefix(5)
            if !Task.isCancelled {
                suggestions = Array(results)
            }
        }
    }

    func clearSuggestions() {
        suggestions = []
    }

    // MARK: - Private

    private func freshCacheData() -> Data? {
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: cacheURL.path),
              let modified = attrs[.modificationDate] as? Date,
              Date().timeIntervalSince(modified) < Self.cacheTTL,
              let data = try? Data(contentsOf: cacheURL) else { return nil }
        return data
    }

    private func loadStaleCache() {
        if let data = try? Data(contentsOf: cacheURL),
           let lib = try? JSONDecoder().decode(CompoundLibrary.self, from: data) {
            allCompounds = lib.compounds
            fetchError = "Compound library may be outdated"
        } else {
            allCompounds = []
            fetchError = "Compound library unavailable"
        }
    }
}
