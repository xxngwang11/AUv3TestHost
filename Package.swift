// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AUv3TestHost",
    platforms: [
        .macOS(.v14),
        .iOS(.v17)
    ],
    products: [
        // Library product for iOS/macOS app development
        // iOS apps must be built using Xcode, not SPM command-line tools
        .library(
            name: "AUv3TestHost",
            targets: ["AUv3TestHost"]
        ),
    ],
    targets: [
        .target(
            name: "AUv3TestHost",
            dependencies: [],
            path: "AUv3TestHost",
            exclude: ["Info.plist"]
        ),
    ]
)