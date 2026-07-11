import SwiftUI
import SwiftGuardData

/// D-05: a visible PL⇄EN switch on every screen, the same "always-visible
/// toggle" requirement every sibling implements — here, a native SwiftUI
/// `Picker` instead of a web `<nav>` element.
public struct LanguageToggleView: View {
    @Environment(LocalizationManager.self) private var localizationManager

    public init() {}

    public var body: some View {
        Picker("", selection: localeBinding) {
            Text("Polski").tag(AppLocale.polish)
            Text("English").tag(AppLocale.english)
        }
        .pickerStyle(.segmented)
        .fixedSize()
    }

    private var localeBinding: Binding<AppLocale> {
        Binding(
            get: { localizationManager.currentLocale },
            set: { localizationManager.setLocale($0) }
        )
    }
}
