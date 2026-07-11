// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SwiftGuardUI",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "SwiftGuardUI", targets: ["SwiftGuardUI"])
    ],
    dependencies: [
        .package(path: "../SwiftGuardData")
    ],
    targets: [
        .target(
            name: "SwiftGuardUI",
            dependencies: ["SwiftGuardData"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "SwiftGuardUITests_Unit",
            // "SwiftGuardData" is listed explicitly (not just transitively via
            // "SwiftGuardUI") because SPM does not re-export a dependency's own
            // dependencies to a target that merely depends on it — this test
            // target constructs `Framework`/`Threat`/etc. `@Model` fixtures
            // directly, so it needs its own explicit access.
            dependencies: ["SwiftGuardUI", "SwiftGuardData"]
        )
    ]
)
