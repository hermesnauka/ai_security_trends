import Foundation
import SwiftData

/// D-02: this struct's only public method is called from `ContentSeeder`
/// (first launch / app-update path) and from the `BGAppRefreshTask` handler
/// — never from a `ViewModel`. Because this whole app is one compiled
/// binary with no process boundary, `SwiftGuardData`/`SwiftGuardUI` being
/// separate Swift Package Manager targets is what gives this convention
/// actual cross-target teeth via `internal`/`public` access control, backed
/// by a `SwiftLint` custom rule flagging any `SwiftGuardUI` file that
/// references `IntegrityService` by name.
///
/// Per PLAN.md §12: because the app bundle is code-signed by Apple and the
/// sandbox prevents another process from modifying it post-install, this
/// check's primary value is catching a bad build/CI mistake before it
/// ships and detecting corruption of the on-device cache — not detecting a
/// malicious runtime tamperer, the primary concern for every server-based
/// sibling.
public struct IntegrityService: Sendable {
    private let bundle: Bundle

    public init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

    /// @return fileName -> isValid
    public func verify(modelContext: ModelContext) throws -> [String: Bool] {
        guard let hashesUrl = bundle.url(forResource: "hashes", withExtension: "json") else {
            return [:]
        }
        let hashesData = try Data(contentsOf: hashesUrl)
        let expected = try JSONDecoder().decode([String: String].self, from: hashesData)

        var results: [String: Bool] = [:]

        for (fileName, expectedHash) in expected {
            let isValid: Bool
            if let fileUrl = bundle.url(forResource: (fileName as NSString).deletingPathExtension, withExtension: "yaml", subdirectory: "Cornucopia") {
                let data = try Data(contentsOf: fileUrl)
                isValid = Hashing.sha256Hex(data) == expectedHash
            } else {
                isValid = false
            }

            results[fileName] = isValid

            // fileName is @Attribute(.unique) — fetch-then-update-or-insert
            // rather than a blind insert, since re-running verify() (e.g.
            // from the periodic BGAppRefreshTask) must update the existing
            // row, not violate the uniqueness constraint.
            let descriptor = FetchDescriptor<ContentHash>(predicate: #Predicate { $0.fileName == fileName })
            if let existing = try modelContext.fetch(descriptor).first {
                existing.sha256Hash = expectedHash
                existing.verifiedAt = Date()
                existing.isValid = isValid
            } else {
                let record = ContentHash(fileName: fileName, sha256Hash: expectedHash, verifiedAt: Date(), isValid: isValid)
                modelContext.insert(record)
            }
        }

        try modelContext.save()
        return results
    }

    public func allValid(modelContext: ModelContext) throws -> Bool {
        try verify(modelContext: modelContext).values.allSatisfy { $0 }
    }
}
