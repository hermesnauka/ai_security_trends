import SwiftUI

/// PLAN.md §8: `RootView` → `TabView`: Frameworks | Threats | Search |
/// Bookmarks | About — the top-level navigation shell, analogous to
/// app09's WordPress Template Hierarchy routes but native.
public struct RootView: View {
    public init() {}

    public var body: some View {
        TabView {
            FrameworkListView()
                .tabItem { Label("Frameworki", systemImage: "square.grid.2x2") }

            NavigationStack {
                ThreatBrowserView()
            }
            .tabItem { Label("Zagrożenia", systemImage: "exclamationmark.shield") }

            NavigationStack {
                SearchResultsView()
            }
            .tabItem { Label("Szukaj", systemImage: "magnifyingglass") }

            BookmarksView()
                .tabItem { Label("Zakładki", systemImage: "bookmark") }

            AboutView()
                .tabItem { Label("O aplikacji", systemImage: "info.circle") }
        }
    }
}
