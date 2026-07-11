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
            dependencies: ["SwiftGuardUI"]
        )
    ]
)
