import SwiftData
import SwiftUI
import SwiftGuardData

/// D-08: every code sample ships read-only, bundled, never executed. The
/// attack-demo confirmation is a native `.confirmationDialog` — unlike
/// app09's web equivalent, there is no "must also work with JavaScript
/// disabled" constraint to design around here (PLAN.md §0), so a modal
/// sheet is the natural, idiomatic gate rather than a `<details>` fallback.
struct CodeSamplePanelView: View {
    let codeSamples: [CodeSample]
    @State private var selectedLanguage: CodeLanguage = .python
    @State private var pendingAttackDemo: CodeSample?
    @State private var revealedAttackDemoIDs: Set<PersistentIdentifier> = []

    var body: some View {
        if codeSamples.isEmpty {
            Text("Brak jeszcze próbek kodu dla tej mitigacji.")
                .font(.caption)
        } else {
            VStack(alignment: .leading, spacing: 8) {
                Picker("Język", selection: $selectedLanguage) {
                    ForEach(availableLanguages, id: \.self) { language in
                        Text(language.rawValue.uppercased()).tag(language)
                    }
                }
                .pickerStyle(.segmented)

                ForEach(samplesForSelectedLanguage) { sample in
                    if sample.sampleType == .defense {
                        codeBlock(sample)
                    } else {
                        attackDemoBlock(sample)
                    }
                }
            }
            .confirmationDialog(
                "Ten kod celowo demonstruje podatność. Potwierdź, aby go zobaczyć.",
                isPresented: Binding(get: { pendingAttackDemo != nil }, set: { if !$0 { pendingAttackDemo = nil } }),
                titleVisibility: .visible
            ) {
                Button("Rozumiem") {
                    if let sample = pendingAttackDemo {
                        revealedAttackDemoIDs.insert(sample.persistentModelID)
                    }
                    pendingAttackDemo = nil
                }
                Button("Anuluj", role: .cancel) { pendingAttackDemo = nil }
            }
        }
    }

    private var availableLanguages: [CodeLanguage] {
        Array(Set(codeSamples.map(\.language))).sorted { $0.rawValue < $1.rawValue }
    }

    private var samplesForSelectedLanguage: [CodeSample] {
        codeSamples.filter { $0.language == selectedLanguage }
    }

    private func codeBlock(_ sample: CodeSample) -> some View {
        VStack(alignment: .leading) {
            Text(sample.title).font(.caption.bold())
            ScrollView(.horizontal) {
                Text(sample.code).font(.system(.footnote, design: .monospaced))
            }
            Text("\(sample.frameworkHint) — \(sample.versionNote)").font(.caption2).foregroundStyle(.secondary)
        }
    }

    private func attackDemoBlock(_ sample: CodeSample) -> some View {
        VStack(alignment: .leading) {
            Text("ATTACK DEMO — kod podatny, nie używać w produkcji")
                .font(.caption.bold())
                .foregroundStyle(.red)

            if revealedAttackDemoIDs.contains(sample.persistentModelID) {
                codeBlock(sample)
            } else {
                Button("Pokaż kod (VULNERABLE)") {
                    pendingAttackDemo = sample
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
        }
        .padding(8)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(.red, lineWidth: 2))
    }
}
