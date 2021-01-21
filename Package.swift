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
            resources: [
                .copy("Resources/hterm_all.js"),
                .copy("Resources/hterm.html"),
                .copy("Resources/hterm.css"),
                .copy("Resources/hterm_bridge.js"),
            ]
        ),
    ]
)
