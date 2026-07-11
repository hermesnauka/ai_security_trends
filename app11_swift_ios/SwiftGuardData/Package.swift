// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SwiftGuardData",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "SwiftGuardData", targets: ["SwiftGuardData"])
    ],
    dependencies: [
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.1.0"),
        .package(url: "https://github.com/typelift/SwiftCheck.git", from: "0.12.0")
    ],
    targets: [
        .target(
            name: "SwiftGuardData",
            dependencies: ["Yams"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "SwiftGuardDataTests",
            dependencies: ["SwiftGuardData", "SwiftCheck", "Yams"],
            // Every item below is a symlink into `../../SwiftGuardApp/Resources` — the
            // SAME real bundled content the app itself seeds from, not a synthetic
            // duplicate that could silently drift out of sync. This is what lets
            // `TestSupport.inMemoryContainer(seeded: true)` assert realistic facts
            // (e.g. "≥10 frameworks", "20 threats", "5 mitigations, all 5 languages")
            // via `Bundle.module`, entirely through `swift test` — no Xcode project or
            // simulator required. If a new top-level resource is ever added to
            // `SwiftGuardApp/Resources/`, add a matching symlink + entry here too.
            resources: [
                .copy("Cornucopia"),
                .copy("CodeSamples"),
                .copy("frameworks.json"),
                .copy("threats_seed.json"),
                .copy("threat_translations_seed.json"),
                .copy("cross_references_seed.json"),
                .copy("mitigations_seed.json"),
                .copy("code_samples_manifest.json"),
                .copy("hashes.json"),
                .copy("ref-allowlists.json"),
                .copy("mitre-atlas-allowlist.json")
            ]
        )
    ]
)
