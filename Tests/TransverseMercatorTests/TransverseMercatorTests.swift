//
//  PureSwiftTransverseMercatorTests.swift
//  GeographicLibDev
//
//  Created by David Hart on 6/3/2026.
//

import Testing
@testable import TransverseMercator
import TransverseMercatorInternal
import Math
import CoreLocation
import Numerics

let utmFalseEasting : Double = 5e5
let utmNorthShift : Double = 1e7
/// ### TransverseMercator Tests
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
///
@Test func testTransverseMercatorForwardSouthern() {
    let lon0 = centralMeridian(zone: 50)
    let forward = TransverseMercator.UTM.forward(centralMeridian: lon0, geodeticCoordinate: CLLocationCoordinate2D(latitude: -31.93980, longitude: 115.96650))
//    let forward = TransverseMercator.UTM.forward(centralMeridian: lon0, latitude: -31.93980, longitude: 115.96650)
    #expect((forward.x + utmFalseEasting).isApproximatelyEqual(to: 402314.322464520, absoluteTolerance: 1e-9))
    #expect((forward.y + utmNorthShift).isApproximatelyEqual(to: 6465770.872261507, absoluteTolerance: 1e-9))
    #expect(forward.convergence.isApproximatelyEqual(to: 0.5467937033262, absoluteTolerance: 1e-9))
    #expect(forward.centralScale.isApproximatelyEqual(to: 0.999717683177112, absoluteTolerance: 1e-9))
    
}

/// ```zsh
/// % echo 31.93980 115.96650 | GeoConvert -u -s -p 9
/// 50n 402314.322464520 3534229.127738493
/// ```
/// ### Convergence and scale
/// - -c causes GeoConvert to output convergence and scale
/// ```zsh
/// % echo 31.93980 115.96650 | GeoConvert -u -s -p 9 -c
/// -0.5467937033262 0.999717683177112
/// ```
@Test func testTransverseMercatorForwardNorthern() {
    let lon0 = centralMeridian(zone: 50)
    let forward = TransverseMercator.UTM.forward(centralMeridian: lon0, latitude: 31.93980, longitude: 115.96650)
    #expect((forward.x + utmFalseEasting).isApproximatelyEqual(to: 402314.322464520, absoluteTolerance: 1e-9))
    #expect((forward.y).isApproximatelyEqual(to: 3534229.127738493, absoluteTolerance: 1e-9))
    #expect(forward.convergence.isApproximatelyEqual(to: -0.5467937033262, absoluteTolerance: 1e-10))
    #expect(forward.centralScale.isApproximatelyEqual(to: 0.999717683177112, absoluteTolerance: 1e-10))
}

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
///
@Test func testTransverseMercatorReverseSouthern() {
    let lon0 = centralMeridian(zone: 50)
    let reverse = TransverseMercator.UTM.reverse(centralMeridian: lon0, x: 402314.322464520 - utmFalseEasting, y: 6465770.872261507 - utmNorthShift)
    #expect(reverse.coordinate.latitude.isApproximatelyEqual(to: -31.93980, absoluteTolerance: 1e-9))
    #expect(reverse.coordinate.longitude.isApproximatelyEqual(to: 115.96650, absoluteTolerance: 1e-9))
    #expect(reverse.convergence.isApproximatelyEqual(to: 0.5467937033262, absoluteTolerance: 1e-9))
    #expect(reverse.centralScale.isApproximatelyEqual(to: 0.999717683177112, absoluteTolerance: 1e-9))
}
/// ```zsh
/// % echo 31.93980 115.96650 | GeoConvert -u -s -p 9
/// 50n 402314.322464520 3534229.127738493
/// ```
/// ### Convergence and scale
/// - -c causes GeoConvert to output convergence and scale
/// ```zsh
/// % echo 31.93980 115.96650 | GeoConvert -u -s -p 9 -c
/// -0.5467937033262 0.999717683177112
/// ```
@Test func testTransverseMercatorReverseNorthern() {
    let lon0 = centralMeridian(zone: 50)
    let reverse = TransverseMercator.UTM.reverse(centralMeridian: lon0, x: 402314.322464520 - utmFalseEasting, y: 3534229.127738493)
    #expect(reverse.coordinate.latitude.isApproximatelyEqual(to: 31.93980, absoluteTolerance: 1e-9))
    #expect(reverse.coordinate.longitude.isApproximatelyEqual(to: 115.96650, absoluteTolerance: 1e-9))
    #expect(reverse.convergence.isApproximatelyEqual(to: -0.5467937033262, absoluteTolerance: 1e-9))
    #expect(reverse.centralScale.isApproximatelyEqual(to: 0.999717683177112, absoluteTolerance: 1e-9))
}
