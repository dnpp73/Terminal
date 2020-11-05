// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "Terminal",
    platforms: [
        .iOS(.v11),
    ],
    products: [
        .library(name: "Terminal", targets: ["Terminal"]),
    ],
    targets: [
        .target(
            name: "Terminal",
            dependencies: [],
            path: "Sources",
            resources: [
                .process("Resources"),
            ]
        ),
    ]
)
