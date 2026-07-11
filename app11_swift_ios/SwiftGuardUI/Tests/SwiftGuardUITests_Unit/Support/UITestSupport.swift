import Foundation
import SwiftData
@testable import SwiftGuardData

/// Unlike `SwiftGuardDataTests`' `TestSupport` (which seeds from the REAL
/// bundled content via a resource symlink, `../SwiftGuardData/Package.swift`),
/// this package has no such symlink set up — ViewModel-level tests don't need
/// realistic dataset sizes, just a couple of deterministic, hand-inserted
/// rows to exercise loading/filtering/debounce logic against.
@MainActor
enum UITestSupport {
    static func inMemoryContainer() throws -> ModelContainer {
        let schema = Schema([
            Framework.self, Threat.self, CornucopiaCard.self, Mitigation.self,
            CodeSample.self, CrossReference.self, ContentHash.self, Bookmark.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    /// Two frameworks, three threats (two `OWASP_LLM`, one `OWASP_WEB`) —
    /// just enough to exercise framework filtering, severity filtering, and
    /// free-text search without needing the real seed data at all.
    static func insertSampleData(into context: ModelContext) {
        let llmFramework = Framework(code: "OWASP_LLM", name: "OWASP LLM Top 10", version: "2025", frameworkDescription: "", referenceUrl: "")
        let webFramework = Framework(code: "OWASP_WEB", name: "OWASP Web Top 10", version: "2021", frameworkDescription: "", referenceUrl: "")
        context.insert(llmFramework)
        context.insert(webFramework)

        context.insert(Threat(
            code: "LLM01:2025", title: "Prompt Injection", severity: .critical, category: "Injection",
            descriptionEn: "Prompt injection description.", descriptionPl: "",
            attackVector: "", attackSurface: "", stride: [], tags: [], framework: llmFramework
        ))
        context.insert(Threat(
            code: "LLM02:2025", title: "Sensitive Information Disclosure", severity: .high, category: "Disclosure",
            descriptionEn: "Disclosure description.", descriptionPl: "",
            attackVector: "", attackSurface: "", stride: [], tags: [], framework: llmFramework
        ))
        context.insert(Threat(
            code: "A01:2021", title: "Broken Access Control", severity: .critical, category: "Access Control",
            descriptionEn: "Access control description.", descriptionPl: "",
            attackVector: "", attackSurface: "", stride: [], tags: [], framework: webFramework
        ))
    }
}
