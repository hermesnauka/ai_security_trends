import SwiftUI

public struct AboutView: View {
    public init() {}

    public var body: some View {
        NavigationStack {
            List {
                Text("SwiftGuard 2026")
                Text("Treść ma charakter edukacyjny i musi być zweryfikowana wobec oficjalnych źródeł.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("O aplikacji")
        }
    }
}
