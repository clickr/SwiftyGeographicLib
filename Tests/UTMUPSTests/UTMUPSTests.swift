//
//  UTMUPSTests.swift
//  GeographicLibDev
//
//  Created by David Hart on 6/3/2026.
//

import Testing
@testable import UTM
@testable import UPS
import Numerics
import CoreLocation
import UTMUPSProtocol

/// Tests the boundary between UTM and UPS for northern latitudes.
///
/// At exactly 84° N, the behavior switches from UTM to UPS.
@Test func testUTMAndUPSNorthBoundary() throws {
    // UTM is valid up to but not including 84° N
    let utm84 = try UTM(latitude: 83.99, longitude: 0.0)
    #expect(utm84.zone == 31)
    
    // UPS is valid from 84° N and above
    let ups84 = try UPS(latitude: 84.0, longitude: 0.0)
    #expect(ups84.hemisphere == .northern)
    
    // Verify UPS at 84° gives reasonable coordinates
    #expect(ups84.easting.isFinite)
    #expect(ups84.northing.isFinite)
}

/// Tests the boundary between UTM and UPS for southern latitudes.
///
/// At exactly -80° S, the behavior switches from UTM to UPS.
@Test func testUTMAndUPPSouthBoundary() throws {
    // UTM is valid up to but not including -80° S
    let utm80 = try UTM(latitude: -79.99, longitude: 0.0)
    #expect(utm80.zone == 31)
    
    // UPS is valid from -80° S and below
    let ups80 = try UPS(latitude: -80.0, longitude: 0.0)
    #expect(ups80.hemisphere == .southern)
    
    // Verify UPS at -80° gives reasonable coordinates
    #expect(ups80.easting.isFinite)
    #expect(ups80.northing.isFinite)
}

/// Tests that coordinates very close to the boundary work correctly.
@Test func testBoundaryContinuity() throws {
    // Just inside UTM zone (83.999° N)
    let utmNear = try UTM(latitude: 83.999, longitude: 0.0)
    
    // At UPS boundary (84° N)
    let upsAt = try UPS(latitude: 84.0, longitude: 0.0)
    
    // Both should produce valid results
    #expect(utmNear.easting.isFinite)
    #expect(utmNear.northing.isFinite)
    #expect(upsAt.easting.isFinite)
    #expect(upsAt.northing.isFinite)
}

/// Tests that zone calculation gives correct results at boundaries.
@Test func testZoneCalculationAtBoundary() throws {
    // Zone 1 at -180° to -174°
    let zone1 = try UTM(latitude: 0.0, longitude: -177.0)
    #expect(zone1.zone == 1)
    
    // Zone 60 at 174° to 180°
    let zone60 = try UTM(latitude: 0.0, longitude: 177.0)
    #expect(zone60.zone == 60)
}

/// Tests that a point at the central meridian of a zone is handled correctly.
@Test func testCentralMeridian() throws {
    // Zone 32 covers 6° E to 12° E, central meridian is 9° E
    let zone32 = try UTM(latitude: 0.0, longitude: 9.0)
    #expect(zone32.zone == 32)
    #expect(zone32.hemisphere == .northern)
    
    // At central meridian, convergence should be very small (near 0)
    #expect(abs(zone32.convergence) < 0.001)
}

/// Tests hemisphere determination based on latitude.
@Test func testHemisphereDetermination() throws {
    // Exactly on equator
    let equator = try UTM(latitude: 0.0, longitude: 0.0)
    #expect(equator.hemisphere == .northern)
    
    // Just north of equator
    let north = try UTM(latitude: 0.001, longitude: 0.0)
    #expect(north.hemisphere == .northern)
    
    // Just south of equator
    let south = try UTM(latitude: -0.001, longitude: 0.0)
    #expect(south.hemisphere == .southern)
}

/// Tests that round-trip conversion (forward then reverse) maintains accuracy.
@Test func testUTMRoundTrip() throws {
    // Test multiple points
    let testPoints: [(Double, Double)] = [
        (45.0, -75.0),   // Northern hemisphere
        (-45.0, 75.0),  // Southern hemisphere
        (0.0, 0.0),     // Equator, prime meridian
        (60.0, 179.0), // Near zone boundary
        (-60.0, -179.0) // Near zone boundary southern
    ]
    
    for (lat, lon) in testPoints {
        let utm = try UTM(latitude: lat, longitude: lon)
        let roundTrip = try UTM(
            hemisphere: utm.hemisphere,
            zone: utm.zone,
            easting: utm.easting,
            northing: utm.northing
        )
        
        #expect(roundTrip.locationCoordinate2D.latitude.isApproximatelyEqual(to: lat, absoluteTolerance: 1e-9))
        #expect(roundTrip.locationCoordinate2D.longitude.isApproximatelyEqual(to: lon, absoluteTolerance: 1e-9))
    }
}

/// Tests that round-trip conversion maintains accuracy for UPS.
@Test func testUPSRoundTrip() throws {
    // Test multiple points in polar regions
    let testPoints: [(Double, Double, UTMUPSProtocol.Hemisphere)] = [
        (85.0, 0.0, .northern),
        (89.0, 90.0, .northern),
        (-85.0, 0.0, .southern),
        (-89.0, -90.0, .southern)
    ]
    
    for (lat, lon, hemisphere) in testPoints {
        let ups = try UPS(latitude: lat, longitude: lon)
        #expect(ups.hemisphere == hemisphere)
        
        let roundTrip = try UPS(hemisphere: ups.hemisphere, easting: ups.easting, northing: ups.northing)
        
        #expect(roundTrip.locationCoordinate2D.latitude.isApproximatelyEqual(to: lat, absoluteTolerance: 1e-9))
        #expect(roundTrip.locationCoordinate2D.longitude.isApproximatelyEqual(to: lon, absoluteTolerance: 1e-9))
    }
}
