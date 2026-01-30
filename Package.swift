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
        .executable(
            name: "AUv3TestHost",
            targets: ["AUv3TestHost"]
        ),
    ],
    targets: [
        .executableTarget(
            name: "AUv3TestHost",
            dependencies: [],
            path: "AUv3TestHost"
        ),
    ]
)