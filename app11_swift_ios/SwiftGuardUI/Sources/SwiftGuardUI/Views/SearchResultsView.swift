import SwiftData
import SwiftUI
import SwiftGuardData

public struct SearchResultsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(LocalizationManager.self) private var localizationManager
    @State private var viewModel: SearchViewModel?

    public init() {}

    public var body: some View {
        List {
            if let viewModel {
                Section("Zagrożenia") {
                    ForEach(viewModel.results.filter { $0.kind == .threat }, id: \.code) { result in
                        NavigationLink(value: result.code) {
                            VStack(alignment: .leading) {
                                Text(result.title).font(.headline)
                                Text(result.excerpt).font(.caption).lineLimit(2)
                            }
                        }
                    }
                }
                Section("Karty Cornucopia") {
                    ForEach(viewModel.results.filter { $0.kind == .card }, id: \.code) { result in
                        VStack(alignment: .leading) {
                            Text(result.code).font(.headline)
                            Text(result.excerpt).font(.caption).lineLimit(2)
                        }
                    }
                }
            }
        }
        .searchable(text: Binding(
            get: { viewModel?.queryText ?? "" },
            set: { newValue in
                viewModel?.queryText = newValue
                viewModel?.search()
            }
        ))
        .navigationTitle("Wyszukiwanie")
        .navigationDestination(for: String.self) { threatCode in
            ThreatDetailView(threatCode: threatCode)
        }
        .task {
            if viewModel == nil {
                viewModel = SearchViewModel(modelContext: modelContext, localizationManager: localizationManager)
            }
        }
    }
}
