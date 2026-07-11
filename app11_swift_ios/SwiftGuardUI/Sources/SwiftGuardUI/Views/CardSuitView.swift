import SwiftData
import SwiftUI
import SwiftGuardData

/// Generic, parameterized by suit OR edition — backs US-05–US-12 (FRE, LLM,
/// AAI, CLD, STRIDE, MLSec, Mobile, DevOps, Website App) with one view,
/// mirroring app09's `suit-archive.php`.
public struct CardSuitView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(LocalizationManager.self) private var localizationManager
    @State private var viewModel: CardSuitViewModel?

    let suitCode: String?
    let edition: String?
    let title: String

    public init(suitCode: String? = nil, edition: String? = nil, title: String) {
        self.suitCode = suitCode
        self.edition = edition
        self.title = title
    }

    public var body: some View {
        List {
            ForEach(viewModel?.cards ?? []) { card in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(card.cardId).font(.caption.bold())
                        if card.isCritical {
                            Text("AUTONOMY RISK")
                                .font(.caption2.bold())
                                .padding(.horizontal, 4)
                                .background(.orange.opacity(0.2))
                                .foregroundStyle(.orange)
                                .clipShape(Capsule())
                        }
                        Spacer()
                        if card.kind.isDesignHarm {
                            Text("harm projektowy")
                                .font(.caption2.bold())
                                .padding(.horizontal, 4)
                                .background(.purple.opacity(0.2))
                                .foregroundStyle(.purple)
                                .clipShape(Capsule())
                        } else if let severity = card.kind.severity {
                            SeverityBadge(severity: severity)
                        }
                    }
                    Text(card.localizedDescription(localizationManager.currentLocale)).font(.subheadline)
                    if !card.owaspRefs.isEmpty {
                        Text(card.owaspRefs.joined(separator: ", ")).font(.caption2).foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }

            if let viewModel, viewModel.cards.isEmpty {
                Text("Brak kart dla podanego suit/edition.")
            }
        }
        .navigationTitle(title)
        .task {
            if viewModel == nil {
                viewModel = CardSuitViewModel(modelContext: modelContext)
            }
            if let suitCode {
                viewModel?.loadSuit(suitCode)
            } else if let edition {
                viewModel?.loadEdition(edition)
            }
        }
    }
}
