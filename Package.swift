// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Qdrant",
    platforms: [.macOS(.v11)],
    products: [
        .library(name: "Qdrant", targets: ["Qdrant"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-http-types.git", .upToNextMajor(from: "0.2.0")),
        .package(url: "https://github.com/Flight-School/AnyCodable", .upToNextMajor(from: "0.6.7"))
    ],
    targets: [
        .target(name: "Qdrant",
                dependencies: [
                    "AnyCodable",
                    .product(name: "HTTPTypes", package: "swift-http-types")
                ]),
        .testTarget(name: "QdrantTests",
                    dependencies: [
                        "Qdrant",
                        .product(name: "HTTPTypesFoundation", package: "swift-http-types")
                    ]),
    ]
)
