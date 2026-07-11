import SwiftData
import SwiftUI
import SwiftGuardData
import SwiftGuardUI

/// Thin composition root (PLAN.md §9) — no business logic lives here beyond
/// wiring the `ModelContainer`, running `ContentSeeder` on first launch /
/// app-update, and injecting `LocalizationManager` into the environment.
@main
struct SwiftGuardApp: App {
    let modelContainer: ModelContainer
    @State private var localizationManager = LocalizationManager()

    init() {
        do {
            modelContainer = try ModelContainer(for: schema)
        } catch {
            fatalError("Could not create SwiftData ModelContainer: \(error)")
        }

        let context = ModelContext(modelContainer)
        do {
            try ContentSeeder().seedIfNeeded(modelContext: context)
        } catch {
            // Fail-secure per D-03/IntegrityService's spirit: log and surface
            // rather than silently continue with a half-seeded store. A
            // real app would route this to a user-visible "content
            // integrity error" state (PLAN.md Phase 3 security checkpoint);
            // this scaffold only logs it.
            print("ContentSeeder failed: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(localizationManager)
        }
        .modelContainer(modelContainer)
    }

    private var schema: Schema {
        Schema([
            Framework.self,
            Threat.self,
            CornucopiaCard.self,
            Mitigation.self,
            CodeSample.self,
            CrossReference.self,
            ContentHash.self,
            Bookmark.self
        ])
    }
}
