// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TextCaptureServer",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "TextCaptureServer", targets: ["TextCaptureServer"]),
        .executable(name: "example", targets: ["TextCaptureServerExample"])
    ],
    dependencies: [
        .package(url: "https://github.com/Kitura/Kitura", from: "2.8.0"),
        .package(url: "https://github.com/Kitura/Kitura-CORS.git", from: "2.1.201"),
        .package(url: "../text-recognizer", from: "0.1.0"),
        .package(url: "../papago", from: "0.1.0"),
    ],
    targets: [
        .target(
            name: "TextCaptureServer",
            dependencies: [
                "Kitura",
                .product(name: "KituraCORS", package: "Kitura-CORS"),
                .product(name: "TextRecognizer", package: "text-recognizer"),
                .product(name: "Papago", package: "papago"),
            ]
        ),
        .executableTarget(
            name: "TextCaptureServerExample",
            dependencies: ["TextCaptureServer"]
        ),
    ]
)
