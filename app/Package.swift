// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "Alacrity",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(name: "Alacrity", targets: ["Alacrity"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "Alacrity",
            dependencies: [],
            path: "Sources/Alacrity",
            swiftSettings: [
                .define("APPKIT_UI")
            ]
        )
    ]
) 