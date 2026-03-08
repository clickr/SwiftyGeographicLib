//
//  PureSwiftTransverseMercatorTests.swift
//  GeographicLibDev
//
//  Created by David Hart on 6/3/2026.
//

import Testing
@testable import TransverseMercator
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

// WGS84 reference values from GeographicLib 2.7 (C++)
// Generated via TransverseMercator::UTM() internal fields.
// Accessible here via @testable import TransverseMercator.

@Test func initUTM() {
    let f = 1 / 298.257223563  // WGS84 flattening
    let a = 6378137.0          // WGS84 semi-major axis
    let internalUTM = computeInternalTransverseMercator(flattening: f, equatorialRadius: a)

    #expect(internalUTM.n  == 1.67922038638370469e-03)
    #expect(internalUTM.a1 == 6.36744914582341444e+06)
    #expect(internalUTM.b1 == 9.98324298431252699e-01)
    #expect(internalUTM.c  == 1.00335655524931533e+00)
    #expect(internalUTM.e2 == 6.69437999014131646e-03)
    #expect(internalUTM.e2m == 9.93305620009858670e-01)
    #expect(internalUTM.es == 8.18191908426214864e-02)

    let alp = internalUTM.alp
    #expect(alp[1] == 8.37731820624469832e-04)
    #expect(alp[2] == 7.60852777357230854e-07)
    #expect(alp[3] == 1.19764550332945254e-09)
    #expect(alp[4] == 2.42917060720135907e-12)
    #expect(alp[5] == 5.71175767786580385e-15)
    #expect(alp[6] == 1.49111773125838951e-17)

    let bet = internalUTM.bet
    #expect(bet[1] == 8.37732164057948645e-04)
    #expect(bet[2] == 5.90587015222020260e-08)
    #expect(bet[3] == 1.67348266528399683e-10)
    #expect(bet[4] == 2.16479804006270561e-13)
    #expect(bet[5] == 3.78797804616860576e-16)
    #expect(bet[6] == 7.24874889069415449e-19)
}
