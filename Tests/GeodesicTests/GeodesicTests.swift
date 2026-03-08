//
//  GeodesicTests.swift
//  SwiftGeoLib
//
//  Created by David Hart on 7/3/2026.
//

import XCTest
@testable import Geodesic

final class GeodesicTests: XCTestCase {

    let geo = Geodesic.wgs84

    // MARK: - Tolerances

    /// Latitude/longitude tolerance in degrees (≈ 11 µm on the equator).
    private let latLonTol = 1e-10
    /// Azimuth tolerance in degrees.
    private let aziTol    = 1e-10
    /// Distance tolerance in metres (0.1 mm).
    private let distTol   = 1e-4
    /// Arc-length tolerance in degrees.
    private let arcTol    = 1e-10
    /// Reduced-length tolerance in metres (0.1 mm).
    private let mTol      = 1e-4
    /// Geodesic-scale tolerance (dimensionless).
    private let MTol      = 1e-12

    // MARK: - Direct problem

    /// Reference values cross-checked with `GeodSolve -f`.
    func testDirectStandardMidLatitude() {
        // GeodSolve: "40.6 -73.8 45 10000000" → lat2 lon2 azi2 s12 a12 m12 M12 M21
        let r = geo.direct(latitude: 40.6, longitude: -73.8, azimuth: 45, distance: 10_000_000)
        XCTAssertEqual(r.latitude,  32.642844327605523,  accuracy: latLonTol)
        XCTAssertEqual(r.longitude, 49.011039583224175,  accuracy: latLonTol)
        XCTAssertEqual(r.azimuth,   140.366230465350952, accuracy: aziTol)
        XCTAssertEqual(r.distance,  10_000_000.0,        accuracy: distTol)
        XCTAssertEqual(r.arcLength, 89.958719298608429,  accuracy: arcTol)
    }

    func testDirectEquatorial() {
        // GeodSolve: "0 0 90 10000000"
        let r = geo.direct(latitude: 0, longitude: 0, azimuth: 90, distance: 10_000_000)
        XCTAssertEqual(r.latitude,  0.0,                 accuracy: latLonTol)
        XCTAssertEqual(r.longitude, 89.831528411952149,  accuracy: latLonTol)
        XCTAssertEqual(r.azimuth,   90.0,                accuracy: aziTol)
        XCTAssertEqual(r.arcLength, 90.133729742285553,  accuracy: arcTol)
    }

    func testDirectMeridionalNorth() {
        // GeodSolve: "0 0 0 10000000"
        let r = geo.direct(latitude: 0, longitude: 0, azimuth: 0, distance: 10_000_000)
        XCTAssertEqual(r.latitude,  89.982400758562761, accuracy: latLonTol)
        XCTAssertEqual(r.longitude,  0.0,              accuracy: latLonTol)
        XCTAssertEqual(r.azimuth,    0.0,              accuracy: aziTol)
    }

    func testDirectMeridionalSouth() {
        // GeodSolve: "0 0 180 10000000"
        let r = geo.direct(latitude: 0, longitude: 0, azimuth: 180, distance: 10_000_000)
        XCTAssertEqual(r.latitude,  -89.982400758562761, accuracy: latLonTol)
        XCTAssertEqual(r.longitude,   0.0,              accuracy: latLonTol)
        XCTAssertEqual(r.azimuth,   180.0,              accuracy: aziTol)
    }

    func testDirectNearPolar() {
        // GeodSolve: "89 0 45 200000"
        let r = geo.direct(latitude: 89, longitude: 0, azimuth: 45, distance: 200_000)
        XCTAssertEqual(r.latitude,  88.706239657706703,  accuracy: latLonTol)
        XCTAssertEqual(r.longitude, 101.878985961453139, accuracy: latLonTol)
        XCTAssertEqual(r.azimuth,   146.867936595203901, accuracy: aziTol)
    }

    func testDirectShortLine() {
        // Paris, 1 km at azimuth 37.95°. GeodSolve: "48.8567 2.3508 37.95 1000"
        let r = geo.direct(latitude: 48.8567, longitude: 2.3508, azimuth: 37.95, distance: 1000)
        XCTAssertEqual(r.latitude,  48.863790503613686, accuracy: latLonTol)
        XCTAssertEqual(r.longitude,  2.359181685048880, accuracy: latLonTol)
        XCTAssertEqual(r.azimuth,   37.956312306456056, accuracy: aziTol)
        XCTAssertEqual(r.distance,   1000.0,            accuracy: distTol)
        XCTAssertEqual(r.arcLength,  0.008996245473015, accuracy: arcTol)
    }

    func testDirectSouthernHemisphere() {
        // Sydney, 500 km at 225°. GeodSolve: "-33.8688 151.2093 225 500000"
        let r = geo.direct(latitude: -33.8688, longitude: 151.2093, azimuth: 225, distance: 500_000)
        XCTAssertEqual(r.latitude,  -36.992213832239848, accuracy: latLonTol)
        XCTAssertEqual(r.longitude, 147.238604387768675, accuracy: latLonTol)
        XCTAssertEqual(r.azimuth,  -132.696655370187273, accuracy: aziTol)
    }

    // MARK: - Direct — reduced length and geodesic scale

    func testDirectFullOutput() {
        // GeodSolve -f: "40.6 -73.8 45 10000000" → ... m12=6383673.3758063782 M12=0.00411... M21=0.00342...
        let r = geo.direct(latitude: 40.6, longitude: -73.8, azimuth: 45, distance: 10_000_000)
        XCTAssertEqual(r.reducedLength   ?? .nan, 6383673.3758063782,   accuracy: mTol)
        XCTAssertEqual(r.geodesicScale12 ?? .nan, 0.00411601372959962,  accuracy: MTol)
        XCTAssertEqual(r.geodesicScale21 ?? .nan, 0.00342033973082048,  accuracy: MTol)
    }

    func testDirectShortLineFullOutput() {
        // GeodSolve -f: "48.8567 2.3508 37.95 1000" → m12=999.9999959062 M12=0.9999... M21=0.9999...
        let r = geo.direct(latitude: 48.8567, longitude: 2.3508, azimuth: 37.95, distance: 1000)
        XCTAssertEqual(r.reducedLength   ?? .nan, 999.9999959062,        accuracy: mTol)
        XCTAssertEqual(r.geodesicScale12 ?? .nan, 0.99999998772008492,   accuracy: MTol)
        XCTAssertEqual(r.geodesicScale21 ?? .nan, 0.99999998772009169,   accuracy: MTol)
    }

    // MARK: - Inverse problem

    func testInverseRoundTrip() {
        // Inverse of the Case 1 direct should recover azimuth1=45° and distance=10 Mm.
        // GeodSolve -i -f: "40.6 -73.8 32.642... 49.011..."
        let r = geo.inverse(latitude1: 40.6, longitude1: -73.8,
                            latitude2: 32.642844327605523, longitude2: 49.011039583224175)
        XCTAssertEqual(r.azimuth1,  45.0,                 accuracy: aziTol)
        XCTAssertEqual(r.azimuth2,  140.366230465350952,  accuracy: aziTol)
        XCTAssertEqual(r.distance,  10_000_000.0,         accuracy: distTol)
        XCTAssertEqual(r.arcLength, 89.958719298608429,   accuracy: arcTol)
    }

    func testInverseMeridional() {
        // GeodSolve -i -f: "0 0 89.982... 0"
        let r = geo.inverse(latitude1: 0, longitude1: 0,
                            latitude2: 89.982400758562761, longitude2: 0)
        XCTAssertEqual(r.azimuth1,  0.0,          accuracy: aziTol)
        XCTAssertEqual(r.azimuth2,  0.0,          accuracy: aziTol)
        XCTAssertEqual(r.distance,  10_000_000.0, accuracy: distTol)
    }

    func testInverseShortLine() {
        // Paris to Toulouse. GeodSolve -i -f: "48.8567 2.3508 43.6047 1.4442"
        let r = geo.inverse(latitude1: 48.8567, longitude1: 2.3508,
                            latitude2: 43.6047,  longitude2: 1.4442)
        XCTAssertEqual(r.azimuth1, -172.838625614387070, accuracy: aziTol)
        XCTAssertEqual(r.azimuth2, -173.494005803912984, accuracy: aziTol)
        XCTAssertEqual(r.distance,   587951.8374173329,  accuracy: distTol)
        XCTAssertEqual(r.arcLength,    5.290171324450878, accuracy: arcTol)
    }

    func testInverseNearAntipodal() {
        // GeodSolve -i: "0 0 0.5 179.5"
        let r = geo.inverse(latitude1: 0, longitude1: 0, latitude2: 0.5, longitude2: 179.5)
        XCTAssertEqual(r.distance, 19_936_288.5789653137, accuracy: distTol)
    }

    func testInverseExactAntipodal() {
        // (0,0) to (0,180): shortest path is over the pole (meridional), not equatorial.
        // GeodSolve -i: "0 0 0 180" → s12 = 20003931.4586254470
        let r = geo.inverse(latitude1: 0, longitude1: 0, latitude2: 0, longitude2: 180)
        XCTAssertEqual(r.distance, 20_003_931.4586254470, accuracy: distTol)
    }

    func testInverseEquatorial() {
        // GeodSolve -i: "0 0 0 89.831..."
        let r = geo.inverse(latitude1: 0, longitude1: 0,
                            latitude2: 0, longitude2: 89.831528411952149)
        XCTAssertEqual(r.azimuth1,  90.0,           accuracy: aziTol)
        XCTAssertEqual(r.azimuth2,  90.0,           accuracy: aziTol)
        XCTAssertEqual(r.distance,  10_000_000.0,   accuracy: distTol)
    }

    // MARK: - Inverse — reduced length and geodesic scale

    func testInverseFullOutput() {
        // GeodSolve -i -f: "48.8567 2.3508 43.6047 1.4442" → m12=587119.7260... M12=0.99575... M21=0.99575...
        let r = geo.inverse(latitude1: 48.8567, longitude1: 2.3508,
                            latitude2: 43.6047,  longitude2: 1.4442)
        XCTAssertEqual(r.reducedLength   ?? .nan, 587119.7260652002,    accuracy: mTol)
        XCTAssertEqual(r.geodesicScale12 ?? .nan, 0.99575625714830673,  accuracy: MTol)
        XCTAssertEqual(r.geodesicScale21 ?? .nan, 0.99575451793057534,  accuracy: MTol)
    }

    // MARK: - GeodesicLine

    func testGeodesicLinePositions() {
        // Paris at azimuth 37.95°. GeodSolve -L 48.8567 2.3508 37.95 < distances
        let line = geo.line(latitude: 48.8567, longitude: 2.3508, azimuth: 37.95)

        // s12 = 1 000 m
        let p1 = line.position(distance: 1_000)
        XCTAssertEqual(p1.latitude,  48.863790503613686, accuracy: latLonTol)
        XCTAssertEqual(p1.longitude,  2.359181685048880, accuracy: latLonTol)
        XCTAssertEqual(p1.azimuth,   37.956312306456056, accuracy: aziTol)

        // s12 = 10 000 m
        let p2 = line.position(distance: 10_000)
        XCTAssertEqual(p2.latitude,  48.927577178040330, accuracy: latLonTol)
        XCTAssertEqual(p2.longitude,  2.434723553065000, accuracy: latLonTol)
        XCTAssertEqual(p2.azimuth,   38.013234164129464, accuracy: aziTol)

        // s12 = 100 000 m
        let p3 = line.position(distance: 100_000)
        XCTAssertEqual(p3.latitude,  49.562637449531962, accuracy: latLonTol)
        XCTAssertEqual(p3.longitude,  3.200864298996305, accuracy: latLonTol)
        XCTAssertEqual(p3.azimuth,   38.593605483775434, accuracy: aziTol)
    }

    func testGeodesicLineMatchesDirect() {
        // GeodesicLine positions must agree with the standalone direct() call.
        let lat1 = 51.5074; let lon1 = -0.1278; let azi1 = 67.3
        let line = geo.line(latitude: lat1, longitude: lon1, azimuth: azi1)
        for km in [100.0, 500.0, 2000.0, 8000.0] {
            let s = km * 1000
            let p = line.position(distance: s)
            let d = geo.direct(latitude: lat1, longitude: lon1, azimuth: azi1, distance: s)
            XCTAssertEqual(p.latitude,  d.latitude,  accuracy: latLonTol, "at \(km) km")
            XCTAssertEqual(p.longitude, d.longitude, accuracy: latLonTol, "at \(km) km")
            XCTAssertEqual(p.azimuth,   d.azimuth,   accuracy: aziTol,    "at \(km) km")
        }
    }

    // MARK: - Round-trip consistency

    func testDirectInverseConsistency() {
        // Direct then Inverse must recover the original azimuth and distance.
        let lat1 = 51.5074; let lon1 = -0.1278   // London
        let azi1 = 123.0;   let s12  = 5_000_000.0
        let d   = geo.direct(latitude: lat1, longitude: lon1, azimuth: azi1, distance: s12)
        let inv = geo.inverse(latitude1: lat1, longitude1: lon1,
                              latitude2: d.latitude, longitude2: d.longitude)
        XCTAssertEqual(inv.azimuth1, azi1, accuracy: aziTol)
        XCTAssertEqual(inv.distance, s12,  accuracy: distTol)
    }

    func testInverseDirectConsistency() {
        // Inverse then Direct must recover point 2.
        let lat1 = -34.0; let lon1 = 18.5   // Cape Town
        let lat2 =  51.5; let lon2 = -0.1   // London
        let inv = geo.inverse(latitude1: lat1, longitude1: lon1, latitude2: lat2, longitude2: lon2)
        let d   = geo.direct(latitude: lat1, longitude: lon1,
                             azimuth: inv.azimuth1, distance: inv.distance)
        XCTAssertEqual(inv.azimuth2, d.azimuth)
        XCTAssertEqual(d.latitude,  lat2, accuracy: latLonTol)
        XCTAssertEqual(d.longitude, lon2, accuracy: latLonTol)
    }
}
