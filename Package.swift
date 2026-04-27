// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AppleWalletPassManager",
    platforms: [.iOS(.v16)],
    products: [
        .library(
            name: "AppleWalletPassManager",
            targets: ["AppleWalletPassManager"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/typelift/SwiftCheck.git", from: "0.12.0"),
    ],
    targets: [
        .target(
            name: "AppleWalletPassManager",
            path: "Sources/AppleWalletPassManager"
        ),
        .testTarget(
            name: "AppleWalletPassManagerTests",
            dependencies: [
                "AppleWalletPassManager",
                "SwiftCheck",
            ],
            path: "Tests/AppleWalletPassManagerTests"
        ),
    ],
    swiftLanguageModes: [.v6]
)
