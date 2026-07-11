import SwiftData
import SwiftUI
import SwiftGuardData

/// US-19: dedicated, not routed through `CardSuitView` — this deck must
/// NEVER render a severity badge (FR-19.2), and `CardKind.severity` is
/// structurally `nil` for every card here (D-03), so there is no field to
/// print even by copy-paste mistake.
public struct DigitalHarmsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(LocalizationManager.self) private var localizationManager
    @State private var viewModel: CardSuitViewModel?

    private static let suitOrder = ["SCO", "ARC", "AGE", "TRU", "POR"]

    public init() {}

    public var body: some View {
        List {
            Section {
                Text("Ta talia nie jest listą podatności technicznych z poziomem severity — modeluje harmy projektowe (wykluczenie cyfrowe, nieprzejrzyste projektowanie) w usługach publicznych, mapowane na OWASP A04:2021 Insecure Design.")
                    .font(.caption)
            }

            ForEach(Self.suitOrder, id: \.self) { suit in
                Section(suit) {
                    ForEach(cards(forSuit: suit)) { card in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(card.cardId).font(.caption.bold())
                                Text("harm projektowy")
                                    .font(.caption2.bold())
                                    .padding(.horizontal, 4)
                                    .background(.purple.opacity(0.2))
                                    .foregroundStyle(.purple)
                                    .clipShape(Capsule())
                            }
                            Text(card.localizedDescription(localizationManager.currentLocale)).font(.subheadline)
                            if !card.owaspRefs.isEmpty {
                                Text(card.owaspRefs.joined(separator: ", ")).font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Digital-by-Default Harms")
        .task {
            if viewModel == nil {
                viewModel = CardSuitViewModel(modelContext: modelContext)
            }
            viewModel?.loadEdition("dbd")
        }
    }

    private func cards(forSuit suit: String) -> [CornucopiaCard] {
        (viewModel?.cards ?? []).filter { $0.suitCode == suit }
    }
}
