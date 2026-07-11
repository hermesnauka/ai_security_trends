/// D-03: an unconditional compile-time guarantee, the strongest tier in this
/// series alongside Rust's `match` and Haskell's `case` — Swift's exhaustive
/// `switch` over an enum with associated values is a hard compiler error with
/// no configuration flag able to disable it, unlike `app10_csharp_react`'s
/// `CS8509` (a warning promoted to error by project config, which could be
/// silently reverted). It is structurally impossible to construct a
/// `.designHarm` case carrying a `Severity` — there is no such initializer.
public enum CardKind: Codable, Equatable, Sendable {
    case technicalThreat(severity: Severity)
    case designHarm

    /// FR-19.2(b) equivalent: callers that need a severity to *display* must
    /// go through this exhaustive switch — there is no other accessor, so a
    /// design-harm card can never have a severity read off it by mistake.
    public var severity: Severity? {
        switch self {
        case .technicalThreat(let severity):
            return severity
        case .designHarm:
            return nil
        }
    }

    public var isDesignHarm: Bool {
        switch self {
        case .technicalThreat:
            return false
        case .designHarm:
            return true
        }
    }
}
