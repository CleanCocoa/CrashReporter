// swift-tools-version:5.0

//  Copyright © 2019 Christian Tietze. All rights reserved. Distributed under the MIT License.

import PackageDescription

let package = Package(
    name: "CrashReporter",
    platforms: [
        .macOS(.v10_11)
    ],
    products: [
        .library(name: "CrashReporter", targets: ["CrashReporter"])
    ],
    targets: [
        .target(name: "CrashReporter"),
        .testTarget(
            name: "CrashReporterTests",
            dependencies: ["CrashReporter"]
        )
    ]
)
