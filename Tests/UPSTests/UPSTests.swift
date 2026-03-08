//
//  UPSTests.swift
//  GeographicLibDev
//
//  Created by David Hart on 6/3/2026.
//

import Testing
@testable import UPS
import Numerics
import CoreLocation
import UTMUPSProtocol
import GeographicError
import PolarStereographic

// Reference values from GeographicLib 2.7 (C++) UTMUPS::Forward/Reverse.

/// Tests that UPS throws an error for latitudes within the UTM zone.
///
/// UPS is only valid for latitudes outside the UTM coverage area
/// (north of 83.5° N or south of 79.5° S).
@Test func testUPSInvalidLatitude() throws {
    // This latitude is in the UTM zone, not UPS
    #expect(throws: UPSError.latitudeOutOfBounds(latitude: 70.0)) {
        try UPS(latitude: 70.0, longitude: 0.0)
    }
}

/// Tests that the UPS forward projection matches GeographicLib
/// for the northern hemisphere.
///
/// Reference: UTMUPS::Forward(84.5, 45.0)
/// zone=0, northp=true, x=2432099.770743945, y=1567900.229256055,
/// gamma=45, k=0.996293297364271191
@Test func testUPSForwardNorth() throws {
    let ups = try UPS(latitude: 84.5, longitude: 45.0)

    #expect(ups.easting.isApproximatelyEqual(to: 2.43209977074394468e+06, absoluteTolerance: 1e-9))
    #expect(ups.northing.isApproximatelyEqual(to: 1.56790022925605532e+06, absoluteTolerance: 1e-9))
    #expect(ups.convergence.isApproximatelyEqual(to: 4.50000000000000000e+01, absoluteTolerance: 1e-9))
    #expect(ups.centralScale.isApproximatelyEqual(to: 9.96293297364271191e-01, absoluteTolerance: 1e-9))
}

/// Tests that the UPS forward projection matches GeographicLib
/// for the southern hemisphere.
///
/// Reference: UTMUPS::Forward(-80.4174, 77.1166)
/// zone=0, northp=false, x=3039440.641302266, y=2237746.759453198,
/// gamma=-77.1166, k=1.00098288665178403
@Test func testUPSForwardSouth() throws {
    let ups = try UPS(latitude: -80.4174, longitude: 77.1166)

    #expect(ups.hemisphere == .southern)
    #expect(ups.easting.isApproximatelyEqual(to: 3.03944064130226616e+06, absoluteTolerance: 1e-9))
    #expect(ups.northing.isApproximatelyEqual(to: 2.23774675945319841e+06, absoluteTolerance: 1e-9))
    #expect(ups.convergence.isApproximatelyEqual(to: -7.71166000000000054e+01, absoluteTolerance: 1e-9))
    #expect(ups.centralScale.isApproximatelyEqual(to: 1.00098288665178403e+00, absoluteTolerance: 1e-9))
}

/// Tests the UPS reverse projection for the southern hemisphere.
///
/// Reference: UTMUPS::Reverse(0, false, 3039440.641302266, 2237746.759453198)
/// lat=-80.4174, lon=77.1166
@Test func testUPSReverseSouthernHemisphere() throws {
    let ups = try UPS(hemisphere: .southern, easting: 3039440.641302266, northing: 2237746.759453198)
    #expect(ups.geodeticCoordinate.latitude.isApproximatelyEqual(to: -80.4174, absoluteTolerance: 1e-6))
    #expect(ups.geodeticCoordinate.longitude.isApproximatelyEqual(to: 77.1166, absoluteTolerance: 1e-6))
}

/// Tests the UPS reverse projection for the northern hemisphere.
///
/// Reference: UTMUPS::Reverse(0, true, 2649639.515832669, 1850018.900096025)
/// lat=84.0, lon=77.0
@Test func testUPSReverseNorthernHemisphere() throws {
    let ups = try UPS(hemisphere: .northern, easting: 2649639.515832669, northing: 1850018.900096025)
    #expect(ups.geodeticCoordinate.latitude.isApproximatelyEqual(to: 84.0, absoluteTolerance: 1e-6))
    #expect(ups.geodeticCoordinate.longitude.isApproximatelyEqual(to: 77.0, absoluteTolerance: 1e-6))
}

/// Reference: echo 88.0 77.0 | GeoConvert -u -p 9
/// n 2216377.647952983 1950045.283817091
@Test func testUPSReverseNorthernHemisphereGeoConvert() throws {
    let ups = try UPS(hemisphere: .northern, easting: 2216377.647952983, northing: 1950045.283817091)
    #expect(ups.geodeticCoordinate.latitude.isApproximatelyEqual(to: 88.0, absoluteTolerance: 1e-6))
    #expect(ups.geodeticCoordinate.longitude.isApproximatelyEqual(to: 77.0, absoluteTolerance: 1e-6))
}

/// Tests that UPS throws an error for invalid latitude (outside [-90, 90]).
@Test func testUPSThrowsForInvalidLatitudeRange() throws {
    // Latitude > 90 is invalid
    #expect(throws: UPSError.invalidLatitude(latitude: 95.0)) {
        try UPS(latitude: 95.0, longitude: 0.0)
    }
    // Latitude < -90 is invalid
    #expect(throws: UPSError.invalidLatitude(latitude: -95.0)) {
        try UPS(latitude: -95.0, longitude: 0.0)
    }
}

/// Tests that UPS throws an error for northern latitudes that are too low.
///
/// Northern latitudes must be >= 83.5°.
@Test func testUPSThrowsForNorthernLatitudeTooLow() throws {
    // 83.0 is below the UPS boundary of 83.5
    #expect(throws: UPSError.latitudeOutOfBounds(latitude: 83.0)) {
        try UPS(latitude: 83.0, longitude: 0.0)
    }
    // 50.0 is well within UTM zone
    #expect(throws: UPSError.latitudeOutOfBounds(latitude: 50.0)) {
        try UPS(latitude: 50.0, longitude: 0.0)
    }
}

/// Tests that UPS throws an error for southern latitudes that are too high.
///
/// Southern latitudes must be < -79.5°.
@Test func testUPSThrowsForSouthernLatitudeTooHigh() throws {
    // -79.0 is above the UPS boundary of -79.5
    #expect(throws: UPSError.latitudeOutOfBounds(latitude: -79.0)) {
        try UPS(latitude: -79.0, longitude: 0.0)
    }
    // -50.0 is well within UTM zone
    #expect(throws: UPSError.latitudeOutOfBounds(latitude: -50.0)) {
        try UPS(latitude: -50.0, longitude: 0.0)
    }
}

/// Tests that UPS throws an error for invalid easting in the northern hemisphere.
///
/// Northern hemisphere valid range is [1,300,000m, 2,700,000m].
@Test func testUPSThrowsForInvalidEastingNorth() throws {
    // Easting below minimum
    #expect(throws: CoordinateError.eastingOutOfBounds(easting: 1000000)) {
        try UPS(hemisphere: .northern, easting: 1000000, northing: 2000000)
    }
    // Easting above maximum
    #expect(throws: CoordinateError.eastingOutOfBounds(easting: 3000000)) {
        try UPS(hemisphere: .northern, easting: 3000000, northing: 2000000)
    }
}

/// Tests that UPS throws an error for invalid northing in the northern hemisphere.
///
/// Northern hemisphere valid range is [1,300,000m, 2,700,000m].
@Test func testUPSThrowsForInvalidNorthingNorth() throws {
    // Northing below minimum
    #expect(throws: CoordinateError.northingOutOfBounds(northing: 1000000)) {
        try UPS(hemisphere: .northern, easting: 2000000, northing: 1000000)
    }
    // Northing above maximum
    #expect(throws: CoordinateError.northingOutOfBounds(northing: 3000000)) {
        try UPS(hemisphere: .northern, easting: 2000000, northing: 3000000)
    }
}

/// Tests that UPS throws an error for invalid easting in the southern hemisphere.
///
/// Southern hemisphere valid range is [800,000m, 3,200,000m].
@Test func testUPSThrowsForInvalidEastingSouth() throws {
    // Easting below minimum
    #expect(throws: CoordinateError.eastingOutOfBounds(easting: 500000)) {
        try UPS(hemisphere: .southern, easting: 500000, northing: 2000000)
    }
    // Easting above maximum
    #expect(throws: CoordinateError.eastingOutOfBounds(easting: 4000000)) {
        try UPS(hemisphere: .southern, easting: 4000000, northing: 2000000)
    }
}

/// Tests that UPS throws an error for invalid northing in the southern hemisphere.
///
/// Southern hemisphere valid range is [800,000m, 3,200,000m].
@Test func testUPSThrowsForInvalidNorthingSouth() throws {
    // Northing below minimum
    #expect(throws: CoordinateError.northingOutOfBounds(northing: 500000)) {
        try UPS(hemisphere: .southern, easting: 2000000, northing: 500000)
    }
    // Northing above maximum
    #expect(throws: CoordinateError.northingOutOfBounds(northing: 4000000)) {
        try UPS(hemisphere: .southern, easting: 2000000, northing: 4000000)
    }
}
