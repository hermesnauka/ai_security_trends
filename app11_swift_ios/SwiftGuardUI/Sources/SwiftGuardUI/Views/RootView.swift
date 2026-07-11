import SwiftUI

/// PLAN.md §8: `RootView` → `TabView`: Frameworks | Threats | Search |
/// Bookmarks | About — the top-level navigation shell, analogous to
/// app09's WordPress Template Hierarchy routes but native.
public struct RootView: View {
    public init() {}

    public var body: some View {
        // Accessibility identifiers below are stable, English, test-only
        // handles — deliberately separate from the visible Polish labels, so
        // `XCUITest` (see `SwiftGuardUITests/`) doesn't break every time a
        // display string changes or gets translated.
        TabView {
            FrameworkListView()
                .tabItem { Label("Frameworki", systemImage: "square.grid.2x2") }
                .accessibilityIdentifier("tab-frameworks")

            NavigationStack {
                ThreatBrowserView()
            }
            .tabItem { Label("Zagrożenia", systemImage: "exclamationmark.shield") }
            .accessibilityIdentifier("tab-threats")

            NavigationStack {
                SearchResultsView()
            }
            .tabItem { Label("Szukaj", systemImage: "magnifyingglass") }
            .accessibilityIdentifier("tab-search")

            BookmarksView()
                .tabItem { Label("Zakładki", systemImage: "bookmark") }
                .accessibilityIdentifier("tab-bookmarks")

            AboutView()
                .tabItem { Label("O aplikacji", systemImage: "info.circle") }
                .accessibilityIdentifier("tab-about")
        }
    }
}
