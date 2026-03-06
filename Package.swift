// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "GeographicLibDev",
    platforms: [.macOS(.v15)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "TransverseMercator",
            targets: ["TransverseMercator"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-numerics", from: "1.0.0")],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
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
            dependencies: ["Math"]
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
            dependencies: ["PolarStereographic", "Math", "GeographicError", "UTMUPSProtocol"]
        ),
        .target(
            name: "UTM",
            dependencies: ["TransverseMercator", "Math", "GeographicError", "UTMUPSProtocol"]
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
            name: "Math"
        ),
        .target(
            name: "UTMUPSProtocol"
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
                           "SimpleGeographicLib",
                           "Math",
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
            dependencies: ["UTM", .product(name: "Numerics", package: "swift-numerics")]
        ),
        .testTarget(
            name: "UPSTests",
            dependencies: ["UPS", "SimpleGeographicLib", .product(name: "Numerics", package: "swift-numerics")],
            swiftSettings: [.interoperabilityMode(.Cxx)]
        ),
        .testTarget(
            name: "UTMUPSTests",
            dependencies: ["UTM", "UPS", .product(name: "Numerics", package: "swift-numerics")]
        )
    ],
    cxxLanguageStandard: .cxx20
)
