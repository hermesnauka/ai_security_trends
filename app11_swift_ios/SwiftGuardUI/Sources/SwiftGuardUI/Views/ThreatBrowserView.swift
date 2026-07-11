import SwiftData
import SwiftUI
import SwiftGuardData

/// FR-02: filterable threat browser. Unlike every web sibling, there is no
/// "works with JavaScript disabled" concern here at all — SwiftUI has no
/// script-disabled mode, this view is simply the one and only rendering
/// path (PLAN.md §0).
public struct ThreatBrowserView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: ThreatBrowserViewModel?
    let frameworkCode: String?

    public init(frameworkCode: String? = nil) {
        self.frameworkCode = frameworkCode
    }

    public var body: some View {
        List {
            if let viewModel {
                Picker("Severity", selection: Binding(
                    get: { viewModel.selectedSeverity },
                    set: { viewModel.selectedSeverity = $0; viewModel.severityChanged() }
                )) {
                    Text("Wszystkie").tag(Severity?.none)
                    ForEach([Severity.critical, .high, .medium, .low, .info], id: \.self) { severity in
                        Text(severity.rawValue).tag(Severity?.some(severity))
                    }
                }

                ForEach(viewModel.threats) { threat in
                    NavigationLink(value: threat.code) {
                        VStack(alignment: .leading) {
                            HStack {
                                Text(threat.code).font(.caption).foregroundStyle(.secondary)
                                SeverityBadge(severity: threat.severity)
                            }
                            Text(threat.title).font(.headline)
                        }
                    }
                    .accessibilityIdentifier("threat-row-\(threat.code)")
                }

                if viewModel.threats.isEmpty {
                    Text("Brak wyników dla podanych filtrów.")
                }
            }
        }
        .searchable(text: Binding(
            get: { viewModel?.searchText ?? "" },
            set: { viewModel?.searchText = $0 }
        ))
        .navigationTitle("Zagrożenia")
        .navigationDestination(for: String.self) { threatCode in
            ThreatDetailView(threatCode: threatCode)
        }
        .task {
            if viewModel == nil {
                viewModel = ThreatBrowserViewModel(modelContext: modelContext, frameworkCode: frameworkCode)
            }
            viewModel?.load()
        }
    }
}

public struct SeverityBadge: View {
    let severity: Severity

    public init(severity: Severity) {
        self.severity = severity
    }

    public var body: some View {
        Text(severity.rawValue.uppercased())
            .font(.caption2.bold())
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.2))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }

    private var color: Color {
        switch severity {
        case .critical: return .red
        case .high: return .orange
        case .medium: return .yellow
        case .low: return .green
        case .info: return .gray
        }
    }
}
