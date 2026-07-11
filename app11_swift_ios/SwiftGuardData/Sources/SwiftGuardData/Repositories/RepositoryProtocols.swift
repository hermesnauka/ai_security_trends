import Foundation

public struct ThreatFilter: Sendable {
    public var frameworkCode: String?
    public var severity: Severity?
    public var stride: StrideCategory?
    public var category: String?
    public var tag: String?
    public var query: String?

    public init(
        frameworkCode: String? = nil,
        severity: Severity? = nil,
        stride: StrideCategory? = nil,
        category: String? = nil,
        tag: String? = nil,
        query: String? = nil
    ) {
        self.frameworkCode = frameworkCode
        self.severity = severity
        self.stride = stride
        self.category = category
        self.tag = tag
        self.query = query
    }
}

public struct SearchResult: Sendable {
    public let code: String
    public let title: String
    public let excerpt: String
    public let kind: Kind

    public enum Kind: Sendable { case threat, card }
}

public struct MatrixRow: Sendable {
    public let threatCode: String
    public let threatTitle: String
    public let cardIds: [String]
}

public struct Matrix: Sendable {
    public let rows: [MatrixRow]
    public let note: String?
}

public struct StrideHeatmap: Sendable {
    public let categoryCounts: [StrideCategory: Int]
}

@MainActor
public protocol FrameworkRepository {
    func list() throws -> [Framework]
    func detail(code: String) throws -> Framework?
}

@MainActor
public protocol ThreatRepository {
    func list(filter: ThreatFilter) throws -> [Threat]
    func detail(code: String) throws -> Threat?
    func crossReferences(sourceCode: String) throws -> [CrossReference]
}

@MainActor
public protocol CardRepository {
    func bySuit(_ suitCode: String) throws -> [CornucopiaCard]
    func byEdition(_ edition: String) throws -> [CornucopiaCard]
    func byCardId(_ cardId: String) throws -> CornucopiaCard?
    func suits(forEdition edition: String) throws -> [String]
    // Digital-by-Default Harms (US-19): callers read severity only via
    // `card.kind.severity`, the exhaustive switch in D-03 — there is no
    // separate "severity" accessor that could accidentally be called on a
    // design-harm card, because Severity is only reachable through that
    // computed property at all.
}

@MainActor
public protocol MitigationRepository {
    func forThreat(code: String) throws -> [Mitigation]
    func forCard(cardId: String) throws -> [Mitigation]
}

@MainActor
public protocol MatrixRepository {
    func llmMatrix() throws -> Matrix
    func agenticMatrix() throws -> Matrix
    func mobileVsWebMatrix() throws -> (masvsCategories: [String: [String]], webTop10: [(code: String, title: String)])
    func strideHeatmap() throws -> StrideHeatmap
}

@MainActor
public protocol SearchRepository {
    func query(_ text: String, locale: AppLocale) throws -> [SearchResult]
}

@MainActor
public protocol BookmarkRepository {
    func add(code: String) throws
    func remove(code: String) throws
    func list() throws -> [Bookmark]
    // (Optional) sync via SyncCoordinator, which is the ONLY type in this
    // app that imports CloudKit (D-07).
}
