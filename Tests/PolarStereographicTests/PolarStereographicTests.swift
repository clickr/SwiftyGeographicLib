//
//  PolarStereographicTests.swift
//  GeographicLibDev
//
//  Created by David Hart on 6/3/2026.
//

import Testing
@testable import PolarStereographic
import CoreLocation
import Numerics

// WGS84 reference values from GeographicLib 2.7 (C++)
// Generated via PolarStereographic::UPS() internal fields.
// Accessible here via @testable import PolarStereographic.

@Test func test_PolarStereographicInternal() throws {
    let f = 1 / 298.257223563  // WGS84 flattening
    let psi = polarStereographicInternal(flattening: f)

    #expect(psi.e2  == 6.69437999014131646e-03)
    #expect(psi.e2m == 9.93305620009858670e-01)
    #expect(psi.es  == 8.18191908426214864e-02)
    #expect(psi.c   == 1.00335655524931533e+00)
}

// Reference values from GeographicLib 2.7 (C++) PolarStereographic::UPS()
// Forward(false, -80.4174, 77.1166) and roundtrip Reverse.

@Test func testForward() throws {
    let kunlun: CLLocationCoordinate2D = .init(latitude: -80.4174, longitude: 77.1166)

    let forward = PolarStereographic.UPS.forward(coordinate: kunlun)
    #expect(forward.northp == false)
    #expect(forward.x.isApproximatelyEqual(to: 1.03944064130226593e+06, absoluteTolerance: 1e-9))
    #expect(forward.y.isApproximatelyEqual(to: 2.37746759453198320e+05, absoluteTolerance: 1e-9))
    #expect(forward.convergence.isApproximatelyEqual(to: -7.71166000000000054e+01, absoluteTolerance: 1e-9))
    #expect(forward.centralScale.isApproximatelyEqual(to: 1.00098288665178403e+00, absoluteTolerance: 1e-9))
}

/// Test reverse using forward result as input
@Test func testReverse() throws {
    let x = 1.03944064130226593e+06
    let y = 2.37746759453198320e+05

    let reverse = PolarStereographic.UPS.reverse(northp: false, x: x, y: y)
    #expect(reverse.coordinate.latitude.isApproximatelyEqual(to: -8.04174000000000007e+01, absoluteTolerance: 1e-9))
    #expect(reverse.coordinate.longitude.isApproximatelyEqual(to: 7.71166000000000054e+01, absoluteTolerance: 1e-9))
    #expect(reverse.convergence.isApproximatelyEqual(to: -7.71166000000000054e+01, absoluteTolerance: 1e-9))
    #expect(reverse.centralScale.isApproximatelyEqual(to: 1.00098288665178448e+00, absoluteTolerance: 1e-9))
}

/// Reference: echo -80.4174 77.1166 | GeoConvert -u -p 9
/// s 3039440.641302266 2237746.759453198
@Test func testForwardUPSAlgorithm() throws {
    let latitude = -80.4174
    let longitude = 77.1166

    let forward = PolarStereographic.UPS.forward(coordinate: .init(latitude: latitude, longitude: longitude))

    #expect(forward.northp == false)
    #expect((forward.x + 20e5).isApproximatelyEqual(to: 3039440.641302266, absoluteTolerance: 1e-9))
    #expect((forward.y + 20e5).isApproximatelyEqual(to: 2237746.759453198, absoluteTolerance: 1e-9))
}

/// Reference: echo -80.4174 77.1166 | GeoConvert -u -p 9
/// s 3039440.641302266 2237746.759453198
@Test func testReverseUPSAlgorithm() throws {
    let x = 3039440.641302266 - 20e5
    let y = 2237746.759453198 - 20e5

    let reverse = PolarStereographic.UPS.reverse(northp: false, x: x, y: y)

    #expect(reverse.coordinate.latitude.isApproximatelyEqual(to: -80.4174, absoluteTolerance: 1e-6))
    #expect(reverse.coordinate.longitude.isApproximatelyEqual(to: 77.1166, absoluteTolerance: 1e-6))
}
