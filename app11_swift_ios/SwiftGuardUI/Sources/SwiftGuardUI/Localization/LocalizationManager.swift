import Foundation
import SwiftGuardData

/// D-05: an in-app language switch independent of the device's system
/// language, layered on top of (not a replacement for) Xcode's String
/// Catalog infrastructure — the same "use the platform's mature i18n system
/// rather than reinventing it" decision app09 made with WordPress's own
/// gettext, applied here to Apple's own localization stack.
///
/// Scope note: this class tracks the current locale, and every model type's
/// `localizedDescription(_:)` (Threat/CornucopiaCard) already switches
/// content correctly. What's NOT implemented here is PLAN.md D-05's
/// `Bundle.setLanguage`-style runtime bundle-swizzling for the String
/// Catalog's own UI-chrome strings — that would let `Text("key")` calls
/// re-resolve without a view re-render forcing it. Until that's added,
/// UI-chrome strings should be looked up explicitly via this manager's
/// `currentLocale` (e.g. a small localized-string helper) rather than the
/// system `Text(_:)` initializer, or they'll follow the device's system
/// language instead of the in-app toggle.
@Observable
public final class LocalizationManager {
    public private(set) var currentLocale: AppLocale

    public init(initialLocale: AppLocale = .polish) {
        self.currentLocale = initialLocale
    }

    public func setLocale(_ locale: AppLocale) {
        currentLocale = locale
    }

    /// SR-13.1-equivalent: only "pl"/"en" are ever accepted; anything else
    /// (e.g. a malformed deep-link parameter) falls back to the current
    /// locale rather than being applied.
    public func setLocale(fromRawValue rawValue: String) {
        guard let locale = AppLocale(rawValue: rawValue) else { return }
        setLocale(locale)
    }
}
