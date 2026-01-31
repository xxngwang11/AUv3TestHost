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
        // Note: For iOS app development, use Xcode projects instead of SPM executables
        // SPM executable targets are primarily for macOS CLI tools
        // This package structure supports both macOS and iOS via Xcode
        .executable(
            name: "AUv3TestHost",
            targets: ["AUv3TestHost"]
        ),
    ],
    targets: [
        .executableTarget(
            name: "AUv3TestHost",
            dependencies: [],
            path: "AUv3TestHost",
            resources: [
                .process("Info.plist")
            ]
        ),
    ]
)