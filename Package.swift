// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftyGeographicLib",
    platforms: [.macOS(.v15), .iOS(.v17)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "TransverseMercator",
            targets: ["TransverseMercator"]
        ),
        .library(
            name: "UTM",
            targets: ["UTM"]
        ),
        .library(
            name: "PolarStereographic",
            targets: ["PolarStereographic"]
        ),
        .library(
            name: "UPS",
            targets: ["UPS"]
        ),
        .library(
            name: "MagneticModel",
            targets: ["MagneticModel"]
        ),
        .library(
            name: "Geodesic",
            targets: ["Geodesic"]
        ),
        .library(
            name: "Intersect",
            targets: ["Intersect"]
        ),
        .library(
            name: "Ellipsoid",
            targets: ["Ellipsoid"]
        ),
        .library(
            name: "Isogonic",
            targets: ["Isogonic"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-numerics", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "Constants"
        ),
        .target(
            name: "Ellipsoid"
        ),
        .target(
            name: "GeographicError"
        ),
        .target(name: "Intersect",
                dependencies: ["Geodesic", "Math"]),
        .target(
            name: "PolarStereographic",
            dependencies: ["Math", "Ellipsoid"]
        ),
        .target(
            name: "TransverseMercator",
            dependencies: [
                "Math",
                "Ellipsoid",
                .product(name: "ComplexModule", package: "swift-numerics"),
                .product(name: "RealModule", package: "swift-numerics")]
        ),
        .target(
            name: "UPS",
            dependencies: ["PolarStereographic", "Math", "GeographicError", "UTMUPSProtocol", "Constants"]
        ),
        .target(
            name: "UTMUPSProtocol",
            dependencies: ["Constants"],
        ),
        .target(
            name: "UTM",
            dependencies: ["TransverseMercator", "Math", "GeographicError", "UTMUPSProtocol", "Constants"]
        ),
        .target(
            name: "Isogonic",
            dependencies: ["MagneticModel"]
        ),
        .target(
            name: "MagneticModel",
            dependencies: ["Math"],
            resources: [.process("Resources")]
        ),
        .target(
            name: "Math"
        ),
        .testTarget(
            name: "IntersectTests",
            dependencies: ["Intersect",
                           "Geodesic",
                           .product(name: "Numerics", package: "swift-numerics")],
            exclude: ["ReferenceGenerators"]
        ),
        .testTarget(
            name: "MathTests",
            dependencies: ["Math"]),
        .testTarget(
            name: "PolarStereographicTests",
            dependencies: ["PolarStereographic",
                           "Ellipsoid",
                           .product(name: "Numerics", package: "swift-numerics")],
            exclude: ["ReferenceGenerators"]
        ),
        .testTarget(
            name: "TransverseMercatorTests",
            dependencies: ["TransverseMercator",
                           "Math",
                           "Ellipsoid",
                           .product(name: "Numerics", package: "swift-numerics")],
            exclude: ["ReferenceGenerators"]
        ),
        .testTarget(
            name: "UTMTests",
            dependencies: [
                "UTM",
                "Constants",
                .product(name: "Numerics", package: "swift-numerics")]
        ),
        .testTarget(
            name: "UPSTests",
            dependencies: [
                "UPS",
                "Constants",
                .product(name: "Numerics", package: "swift-numerics")],
            exclude: ["ReferenceGenerators"]
        ),
        .testTarget(
            name: "UTMUPSTests",
            dependencies: [
                "UTM",
                "UPS",
                "Constants",
                .product(name: "Numerics", package: "swift-numerics")]
        ),
        .testTarget(
            name: "IsogenicTests",
            dependencies: [
                "Isogonic",
                "MagneticModel",
                .product(name: "Numerics", package: "swift-numerics")]
        ),
        .testTarget(
            name: "MagneticModelTests",
            dependencies: [
                "MagneticModel",
                .product(name: "Numerics", package: "swift-numerics")],
            exclude: ["ReferenceGenerators"]
        ),
        .target(
            name: "Geodesic",
            dependencies: ["Math"]
        ),
        .testTarget(
            name: "GeodesicTests",
            dependencies: [
                "Geodesic",
                .product(name: "Numerics", package: "swift-numerics")]
        )
    ]
)
