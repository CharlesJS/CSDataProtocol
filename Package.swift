// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "CSDataProtocol",
    products: [
        .library(
            name: "CSDataProtocol",
            targets: ["CSDataProtocol"]
        ),
        .library(
            name: "CSDataProtocol+Foundation",
            targets: ["CSDataProtocol_Foundation"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "CSDataProtocol",
            dependencies: []
        ),
        .target(
            name: "CSDataProtocol_Foundation",
            dependencies: ["CSDataProtocol"]
        ),
        .testTarget(
            name: "CSDataProtocolTests",
            dependencies: ["CSDataProtocol_Foundation"]
        ),
    ]
)
