// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "three_js_sensors",
    platforms: [
        .iOS(.v8)
    ],
    products: [
        .library(name: "three-js-sensors", targets: ["three_js_sensors"]),
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "three_js_sensors",
            dependencies: [],
        ),
    ]
)
