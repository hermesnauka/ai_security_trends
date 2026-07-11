import SwiftData
import SwiftUI
import SwiftGuardData

public struct ThreatDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(LocalizationManager.self) private var localizationManager
    @State private var viewModel: ThreatDetailViewModel?
    let threatCode: String

    public init(threatCode: String) {
        self.threatCode = threatCode
    }

    public var body: some View {
        ScrollView {
            if let viewModel, let threat = viewModel.threat {
                VStack(alignment: .leading, spacing: 16) {
                    header(for: threat)
                    section("Przegląd") {
                        Text(threat.localizedDescription(localizationManager.currentLocale))
                    }
                    section("Wektory Ataku") {
                        Text(threat.attackVector)
                        Text("Powierzchnia Ataku").font(.subheadline.bold())
                        Text(threat.attackSurface)
                    }
                    section("Mitigacje") {
                        if viewModel.mitigations.isEmpty {
                            Text("Brak jeszcze zdefiniowanych mitigacji dla tego zagrożenia.")
                        }
                        ForEach(viewModel.mitigations) { mitigation in
                            MitigationView(mitigation: mitigation)
                        }
                    }
                    section("Powiązania Cross-Framework") {
                        if viewModel.crossReferences.isEmpty {
                            Text("Brak jeszcze zdefiniowanych powiązań dla tego zagrożenia.")
                        }
                        ForEach(viewModel.crossReferences, id: \.targetThreatCode) { ref in
                            VStack(alignment: .leading) {
                                Text("\(ref.relationshipType.rawValue.uppercased()) — \(ref.targetThreatCode): \(ref.targetThreatTitle)")
                                    .font(.subheadline.bold())
                                Text(ref.referenceDescription).font(.caption)
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle(threatCode)
        .task {
            if viewModel == nil {
                viewModel = ThreatDetailViewModel(modelContext: modelContext)
            }
            viewModel?.load(threatCode: threatCode)
        }
    }

    private func header(for threat: Threat) -> some View {
        HStack {
            Text(threat.code).font(.caption).foregroundStyle(.secondary)
            Text(threat.title).font(.title2.bold())
            Spacer()
            SeverityBadge(severity: threat.severity)
        }
    }

    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline)
            content()
        }
    }
}

struct MitigationView: View {
    let mitigation: Mitigation

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(mitigation.title).font(.subheadline.bold())
            Text(mitigation.mitigationDescription).font(.footnote)
            HStack {
                Text("Typ: \(mitigation.mitigationType.rawValue)")
                Text("Nakład: \(mitigation.effort.rawValue)")
                Text("Skuteczność: \(mitigation.effectiveness.rawValue)")
            }
            .font(.caption2)
            .foregroundStyle(.secondary)

            CodeSamplePanelView(codeSamples: mitigation.codeSamples)
        }
        .padding(.vertical, 4)
    }
}
