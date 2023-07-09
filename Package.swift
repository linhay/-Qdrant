// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Qdrant",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "Qdrant", targets: ["Qdrant"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", .upToNextMajor(from: "5.7.1")),
        .package(url: "https://github.com/linhay/STJSON", .upToNextMajor(from: "1.0.4")),
    ],
    targets: [
        .target(name: "Qdrant", dependencies: ["STJSON"]),
        .testTarget(name: "QdrantTests", dependencies: ["Qdrant", "Alamofire"]),
    ]
)
