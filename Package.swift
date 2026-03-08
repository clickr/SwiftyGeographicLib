// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftGeoLib",
    platforms: [.macOS(.v15), .iOS(.v17)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "TransverseMercator",
            targets: ["TransverseMercator"]
        ),
        .library(
            name: "TransverseMercatorStatic",
            targets: ["TransverseMercatorStatic"]
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
            name: "StaticUTM",
            targets: ["StaticUTM"]
        ),
        .library(
            name: "MagneticModel",
            targets: ["MagneticModel"]
        ),
        .library(
            name: "Geodesic",
            targets: ["Geodesic"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-numerics", from: "1.0.0")],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "Constants"
        ),
        .target(
            name: "GeographicError"
        ),
        .target(
            name: "PolarStereographic",
            dependencies: ["Math", "PolarStereographicInternal"]
        ),
        .target(
            name: "PolarStereographicInternal",
            dependencies: ["Math"]
        ),
        .target(
            name: "TransverseMercatorInternal",
            dependencies: ["Math", .product(name: "ComplexModule", package: "swift-numerics")]
        ),
        .target(
            name: "TransverseMercatorStatic",
            dependencies: ["Math", "TransverseMercatorInternal", .product(name: "ComplexModule", package: "swift-numerics")]
        ),
        .target(
            name: "TransverseMercator",
            dependencies: [
                "Math",
                "TransverseMercatorInternal",
                .product(name: "ComplexModule", package: "swift-numerics")]
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
            name: "StaticUTM",
            dependencies: ["TransverseMercatorStatic"]
        ),
        .target(
            name: "UTM",
            dependencies: ["TransverseMercator", "StaticUTM", "Math", "GeographicError", "UTMUPSProtocol", "Constants"]
        ),
        .target(name: "SimpleGeographicLib",
                cxxSettings: [
                    .headerSearchPath("include"),
                    .define("GEOGRAPHICLIB_VERSION_STRING", to: "\"2.5\""),
                    .define("GEOGRAPHICLIB_VERSION_MAJOR", to: "2"),
                    .define("GEOGRAPHICLIB_VERSION_MINOR", to: "5"),
                    .define("GEOGRAPHICLIB_VERSION_PATCH", to: "0"),
                    .define("GEOGRAPHICLIB_DATA", to: "\"/usr/local/share/GeographicLib\""),
                    .define("GEOGRAPHICLIB_HAVE_LONG_DOUBLE", to: "0"),
                    .define("GEOGRAPHICLIB_WORDS_BIGENDIAN", to: "0"),
                    .define("GEOGRAPHICLIB_PRECISION", to: "2"),
                    .define("GEOGRAPHICLIB_SHARED_LIB", to: "0")]),
        .target(
            name: "MagneticModel",
            dependencies: ["Math"],
            resources: [.process("Resources")]
        ),
        .target(
            name: "Math"
        ),
        .testTarget(
            name: "MathTests",
            dependencies: ["Math", "SimpleGeographicLib"],
            swiftSettings: [.interoperabilityMode(.Cxx)]),
        .testTarget(
            name: "PolarStereographicInternalTests",
            dependencies: ["PolarStereographicInternal",
                           "SimpleGeographicLib",
                           .product(name: "Numerics", package: "swift-numerics")],
            swiftSettings: [.interoperabilityMode(.Cxx)]
        ),
        .testTarget(
            name: "PolarStereographicTests",
            dependencies: ["PolarStereographic",
                           "SimpleGeographicLib",
                           .product(name: "Numerics", package: "swift-numerics")],
            swiftSettings: [.interoperabilityMode(.Cxx)]
        ),
        .testTarget(
            name: "TransverseMercatorTests",
            dependencies: ["TransverseMercator",
                           "TransverseMercatorStatic",
                           "StaticUTM",
                           "SimpleGeographicLib",
                           "Math",
                           "TransverseMercatorInternal",
                           .product(name: "Numerics", package: "swift-numerics")],
            swiftSettings: [.interoperabilityMode(.Cxx)]
        ),
        .testTarget(
            name: "TransverseMercatorInternalTests",
            dependencies: ["TransverseMercatorInternal", "SimpleGeographicLib"],
            swiftSettings: [.interoperabilityMode(.Cxx)]
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
                "SimpleGeographicLib",
                "Constants",
                .product(name: "Numerics", package: "swift-numerics")],
            swiftSettings: [.interoperabilityMode(.Cxx)]
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
            name: "MagneticModelTests",
            dependencies: [
                "MagneticModel",
                .product(name: "Numerics", package: "swift-numerics")]
        ),
        .target(
            name: "Geodesic",
            dependencies: ["Math"]
        ),
        .testTarget(
            name: "GeodesicTests",
            dependencies: [
                "Geodesic",
                "SimpleGeographicLib",
                .product(name: "Numerics", package: "swift-numerics")],
            swiftSettings: [.interoperabilityMode(.Cxx)]
        )
    ],
    cxxLanguageStandard: .cxx20
)
