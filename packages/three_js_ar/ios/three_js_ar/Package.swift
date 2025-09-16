// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "three_js_ar",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(name: "three-js-ar", targets: ["three_js_ar"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "three_js_ar",
            dependencies: [],
            resources: [
              
            ]
        )
    ]
)
