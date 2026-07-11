import Foundation
import SwiftData
@testable import SwiftGuardData

/// Shared by every test file below — matches the exact convention documented
/// in `../user_stories+tests.md`'s "Konwencje testowe" section:
/// `TestSupport.inMemoryContainer(seeded: true)`.
///
/// `seeded: true` runs the REAL `ContentSeeder` against the REAL bundled
/// content (`Cornucopia/`, `frameworks.json`, etc.) via `Bundle.module` — these
/// resources are symlinks into `../../SwiftGuardApp/Resources` (see
/// `Package.swift`), not a synthetic duplicate, so tests that assert
/// realistic facts ("≥10 frameworks", "20 threats", "all 5 languages") stay
/// true as long as the real seed data does, with no drift risk. This also
/// means these tests exercise the full seeding pipeline (decode → curate →
/// validate → insert) end to end, entirely via `swift test` — no Xcode
/// project, simulator, or `.xcodeproj` required at all.
@MainActor
enum TestSupport {
    static func inMemoryContainer(seeded: Bool) throws -> ModelContainer {
        let schema = Schema([
            Framework.self, Threat.self, CornucopiaCard.self, Mitigation.self,
            CodeSample.self, CrossReference.self, ContentHash.self, Bookmark.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])

        if seeded {
            let seeder = ContentSeeder(bundle: .module, integrityService: IntegrityService(bundle: .module))
            try seeder.seedIfNeeded(modelContext: container.mainContext)
        }

        return container
    }

    /// A directory-backed ad-hoc `Bundle` for tests that need a SMALL,
    /// deliberately-shaped fixture (an unknown-key YAML, an orphan curation
    /// entry, a tampered hash) rather than the full real dataset above.
    /// `Bundle(url:)` treats an arbitrary directory as a flat resource root —
    /// the same lookup shape `bundle.url(forResource:withExtension:subdirectory:)`
    /// expects — so no SPM `resources:` declaration is needed for these
    /// one-off, per-test fixtures.
    static func makeFixtureBundle(files: [String: String]) throws -> Bundle {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("SwiftGuardDataTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)

        for (relativePath, contents) in files {
            let fileURL = root.appendingPathComponent(relativePath)
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try contents.write(to: fileURL, atomically: true, encoding: .utf8)
        }

        guard let bundle = Bundle(url: root) else {
            throw CardDecodeError.missingRequiredField("could not construct a fixture Bundle at \(root.path)")
        }
        return bundle
    }
}
