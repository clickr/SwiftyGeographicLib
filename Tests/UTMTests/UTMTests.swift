//
//  UTMTests.swift
//  GeographicLibDev
//
//  Created by David Hart on 6/3/2026.
//

import Testing
@testable import UTM
import Numerics
import CoreLocation
import GeographicError
import UTMUPSProtocol


/// ## YPPH
/// YPPH is the ICAO designation for Perth Airport.
///
/// ## GeoConvert Utility
/// ## Installation
/// ```zsh
/// brew install geographiclib
/// ```
/// ### UTM/UPS
/// The test data is obtained using the `GeoConvert` command line utility
/// to get UTM coordinates from latitude and longitude
/// - -u output utm/ups
/// - -s use the standard zone for the given latitude and longitude
/// - -p sets the numeric precision (9 is the maximum for decimal degrees)
/// ```zsh
/// % echo -31.93980 115.96650 | GeoConvert -u -s -p 9
/// 50s 402314.322464520 6465770.872261507
/// ```
/// ### Convergence and scale
/// - -c causes GeoConvert to output convergence and scale
/// ```zsh
/// % echo -31.93980 115.96650 | GeoConvert -u -s -p 9 -c
/// 0.5467937033262 0.999717683177112
/// ```
@Test func ypph() throws {
    let ypph = try UTM(latitude: -31.93980, longitude: 115.96650)
    #expect(ypph.zone == 50)
    #expect(ypph.hemisphere == .southern)
    #expect(ypph.easting.isApproximatelyEqual(to: 402314.322464520, absoluteTolerance: 1e-9))
    #expect(ypph.northing.isApproximatelyEqual(to: 6465770.872261507, absoluteTolerance: 1e-9))

    #expect(ypph.convergence.isApproximatelyEqual(to: 0.5467937033262, absoluteTolerance: 1e-9))
    #expect(ypph.centralScale.isApproximatelyEqual(to: 0.999717683177112, absoluteTolerance: 1e-9))
}

@Test func zmck() throws {
    //    echo 47.6514 106.8216 | GeoConvert -u -s -p 9
    //    48n 636793.955125689 5279163.338930206
    let zmck = try UTM(latitude: 47.6514, longitude: 106.8216)
    #expect(zmck.zone == 48)
    #expect(zmck.hemisphere == .northern)
    #expect(zmck.easting.isApproximatelyEqual(to: 636793.955125689, absoluteTolerance: 1e-9))
    #expect(zmck.northing.isApproximatelyEqual(to: 5279163.338930206, absoluteTolerance: 1e-9))

//    echo 47.6514 106.8216 | GeoConvert -u -s -p 9 -c
//    1.3464793685012 0.999829953765984
    #expect(zmck.convergence.isApproximatelyEqual(to: 1.3464793685012, absoluteTolerance: 1e-9))
    #expect(zmck.centralScale.isApproximatelyEqual(to: 0.999829953765984, absoluteTolerance: 1e-9))
}

@Test func testReverseCorrectness() throws {
//    echo 38n 444140.54 3684706.36 | GeoConvert -p 9
//    33.30000003988349 44.39999994689769
    let utm1 = try UTM(hemisphere: .northern, zone: 38, easting: 444140.54, northing: 3684706.36)
    #expect(utm1.locationCoordinate2D.latitude.isApproximatelyEqual(to: 33.30000003988349, absoluteTolerance: 1e-9))
    #expect(utm1.locationCoordinate2D.longitude.isApproximatelyEqual(to: 44.39999994689769, absoluteTolerance: 1e-9))
    #expect(utm1.convergence.isApproximatelyEqual(to: -0.3294222515151, absoluteTolerance: 1e-9))
    #expect(utm1.centralScale.isApproximatelyEqual(to: 0.999638469353107, absoluteTolerance: 1e-9))


//    echo 50s 402357 6465717 | GeoConvert -p 9
//    -31.94028962404897 115.96694602276638
    let utmS = try UTM(hemisphere: .southern, zone: 50, easting: 402357, northing: 6465717)

    let latS = utmS.locationCoordinate2D.latitude
    let lonS = utmS.locationCoordinate2D.longitude

    #expect(latS.isApproximatelyEqual(to: -31.94028962404897, absoluteTolerance: 1e-9))
    #expect(lonS.isApproximatelyEqual(to: 115.96694602276638, absoluteTolerance: 1e-9))
}

/// Tests that UTM throws an error for invalid latitude (outside [-90, 90]).
@Test func testUTMThrowsForInvalidLatitudeRange() throws {
    // Latitude > 90 is invalid
    #expect(throws: CoordinateError.illegalLatitude(latitude: 95.0)) {
        try UTM(latitude: 95.0, longitude: 0.0)
    }
    // Latitude < -90 is invalid
    #expect(throws: CoordinateError.illegalLatitude(latitude: -95.0)) {
        try UTM(latitude: -95.0, longitude: 0.0)
    }
}

/// Tests that UTM throws an error for invalid zone.
///
/// Valid zones are in the range [1, 60].
@Test func testUTMThrowsForInvalidZone() throws {
    // Zone too low
    #expect(throws: UTMError.invalidZone(zone: 0)) {
        try UTM(hemisphere: .northern, zone: 0, easting: 500000, northing: 5000000)
    }
    // Zone too high
    #expect(throws: UTMError.invalidZone(zone: 61)) {
        try UTM(hemisphere: .northern, zone: 61, easting: 500000, northing: 5000000)
    }
}

/// Tests that UTM throws an error for invalid easting in the northern hemisphere.
///
/// Northern hemisphere valid range is [0m, 1,000,000m].
@Test func testUTMThrowsForInvalidEastingNorth() throws {
    // Easting below minimum
    #expect(throws: UTMError.eastingOutOfBounds(easting: -1000)) {
        try UTM(hemisphere: .northern, zone: 32, easting: -1000, northing: 5000000)
    }
    // Easting above maximum
    #expect(throws: UTMError.eastingOutOfBounds(easting: 1001000)) {
        try UTM(hemisphere: .northern, zone: 32, easting: 1001000, northing: 5000000)
    }
}

/// Tests that UTM throws an error for invalid easting in the southern hemisphere.
///
/// Southern hemisphere valid range is [0m, 1,000,000m].
@Test func testUTMThrowsForInvalidEastingSouth() throws {
    // Easting below minimum
    #expect(throws: UTMError.eastingOutOfBounds(easting: -1000)) {
        try UTM(hemisphere: .southern, zone: 32, easting: -1000, northing: 5000000)
    }
    // Easting above maximum
    #expect(throws: UTMError.eastingOutOfBounds(easting: 1001000)) {
        try UTM(hemisphere: .southern, zone: 32, easting: 1001000, northing: 5000000)
    }
}
