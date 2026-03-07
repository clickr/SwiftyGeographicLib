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
import SimpleGeographicLib
import UTMUPSProtocol
import GeographicError
import PolarStereographic

let cppUPS: GeographicLib.PolarStereographic = GeographicLib.PolarStereographic.UPS().pointee

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

/// Tests that the UPS forward projection matches the C++ implementation
/// for the northern hemisphere.
///
/// Uses latitude 84.5° N, longitude 45.0° E.
@Test func testUPSForwardMatchesCPP() throws {
    let latitude = 84.5
    let longitude = 45.0
    
    var x: Double = .nan
    var y: Double = .nan
    var zone : Int32 = -4
    var gamma: Double = .nan
    var k: Double = .nan
    var northp : Bool = false
    
    GeographicLib.UTMUPS.Forward(latitude, longitude, &zone, &northp, &x, &y, &gamma, &k)
    
    let ups = try UPS(latitude: latitude, longitude: longitude)
    
    #expect(zone == 0)
    #expect(ups.easting.isApproximatelyEqual(to: x, absoluteTolerance: 1e-9))
    #expect(ups.northing.isApproximatelyEqual(to: y, absoluteTolerance: 1e-9))
    #expect(ups.convergence.isApproximatelyEqual(to: gamma, absoluteTolerance: 1e-9))
    #expect(ups.centralScale.isApproximatelyEqual(to: k, absoluteTolerance: 1e-9))
}

/// Tests that the UPS forward projection matches the C++ implementation
/// for the southern hemisphere.
///
/// Uses latitude -80.4174° S, longitude 77.1166° E.
@Test func testUPSForwardSouthMatchesCPP() throws {
    let latitude = -80.4174
    let longitude = 77.1166
    
    var x: Double = .nan
    var y: Double = .nan
    var zone : Int32 = -4
    var gamma: Double = .nan
    var k: Double = .nan
    var northp: Bool = false
    
    GeographicLib.UTMUPS.Forward(latitude, longitude, &zone, &northp, &x, &y, &gamma, &k)
    
    let ups = try UPS(latitude: latitude, longitude: longitude)
    
    #expect(ups.hemisphere == .southern)
    #expect(ups.easting.isApproximatelyEqual(to: x, absoluteTolerance: 1e-9))
    #expect(ups.northing.isApproximatelyEqual(to: y, absoluteTolerance: 1e-9))
    #expect(ups.convergence.isApproximatelyEqual(to: gamma, absoluteTolerance: 1e-9))
    #expect(ups.centralScale.isApproximatelyEqual(to: k, absoluteTolerance: 1e-9))
}

/// Tests the UPS reverse projection for the southern hemisphere.
///
/// Uses GeoConvert output: `echo -80.4174 77.1166 | GeoConvert -u -p 9 -z 0`
/// Result: `s 3039440.641302266 2237746.759453198`
@Test func testUPSReverseSouthernHemisphere() throws {
    let ups = try UPS(hemisphere: .southern, easting: 3039440.641302266, northing: 2237746.759453198)
    #expect(ups.geodeticCoordinate.latitude.isApproximatelyEqual(to: -80.4174, absoluteTolerance: 1e-6))
    #expect(ups.geodeticCoordinate.longitude.isApproximatelyEqual(to: 77.1166, absoluteTolerance: 1e-6))
}

/// Tests that the UPS reverse projection matches the C++ implementation
/// for the southern hemisphere.
@Test func testUPSCPPReverseSouthernHemisphere() throws {
    var latitude : Double = .nan
    var longitude : Double = .nan
    
    let easting : Double = 3039440.641302266
    let northing : Double = 2237746.759453198
    
    GeographicLib.UTMUPS.Reverse(0, false, easting, northing, &latitude, &longitude)
    
    let ups = try UPS(hemisphere: .southern, easting: easting, northing: northing)
    #expect(ups.geodeticCoordinate.latitude.isApproximatelyEqual(to: latitude, absoluteTolerance: 1e-6))
    #expect(ups.geodeticCoordinate.longitude.isApproximatelyEqual(to: longitude, absoluteTolerance: 1e-6))
}

/// Tests that the UPS reverse projection matches the C++ implementation
/// for the northern hemisphere.
@Test func testUPSCPPReverseNorthernHemisphere() throws {
    var latitude : Double = .nan
    var longitude : Double = .nan
    let easting : Double = 2649639.515832669
    let northing : Double = 1850018.900096025
    
    GeographicLib.UTMUPS.Reverse(0, true, easting, northing, &latitude, &longitude, false)
    let ups = try UPS(hemisphere: .northern, easting: easting, northing: northing)
    #expect(ups.geodeticCoordinate.latitude.isApproximatelyEqual(to: latitude, absoluteTolerance: 1e-6))
    #expect(ups.geodeticCoordinate.longitude.isApproximatelyEqual(to: longitude, absoluteTolerance: 1e-6))
}

/// Tests the UPS reverse projection for the northern hemisphere.
///
/// Uses GeoConvert output: `echo 88.0 77.0 | GeoConvert -u -p 9`
/// Result: `n 2216377.647952983 1950045.283817091`
@Test func testUPSReverseNorthernHemisphere() throws {
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

