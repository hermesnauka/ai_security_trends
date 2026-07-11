import SwiftData
import SwiftUI
import SwiftGuardData

public struct BookmarksView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var bookmarks: [Bookmark] = []

    public init() {}

    public var body: some View {
        NavigationStack {
            List {
                if bookmarks.isEmpty {
                    Text("Brak zakładek.")
                }
                ForEach(bookmarks) { bookmark in
                    NavigationLink(value: bookmark.threatOrCardCode) {
                        Text(bookmark.threatOrCardCode)
                    }
                }
            }
            .navigationTitle("Zakładki")
            .navigationDestination(for: String.self) { code in
                ThreatDetailView(threatCode: code)
            }
            .task {
                let repository = SwiftDataBookmarkRepository(modelContext: modelContext)
                bookmarks = (try? repository.list()) ?? []
            }
        }
    }
}
