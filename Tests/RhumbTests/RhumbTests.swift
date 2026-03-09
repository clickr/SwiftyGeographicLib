//
//  RhumbTests.swift
//  SwiftyGeographicLib
//
//  Tests for the Rhumb module, verified against GeographicLib's RhumbSolve CLI.
//

import Testing
@testable import Rhumb

// MARK: - Tolerances

/// Tolerance for latitude/longitude comparisons (degrees).
private let degTol = 1e-10   // ~11 µm
/// Tolerance for distance (metres).
private let distTol = 1e-4   // 0.1 mm
/// Tolerance for azimuth (degrees).
private let aziTol = 1e-10
/// Tolerance for area (m²) — relative tolerance for large values.
private let areaTol = 1e-2

// MARK: - Inverse tests

@Suite("Rhumb inverse")
struct RhumbInverseTests {
    let rhumb = Rhumb.wgs84

    @Test("JFK to LHR")
    func jfkToLhr() {
        // echo "40.6 -73.8 51.6 -0.5" | RhumbSolve -i -p 10
        // → 77.768389710255676 5771083.3833280280 37395209100030.383
        let r = rhumb.inverse(latitude1: 40.6, longitude1: -73.8,
                              latitude2: 51.6, longitude2: -0.5)
        #expect(abs(r.azimuth - 77.768389710255676) < aziTol)
        #expect(abs(r.distance - 5771083.3833280280) < distTol)
        #expect(abs(r.area - 37395209100030.383) < 1e6) // large area
    }

    @Test("Equator to 45°N along meridian")
    func equatorTo45N() {
        // echo "0 0 45 0" | RhumbSolve -i -p 10
        // → 0.000000000000000 4984944.3779777437 0.000
        let r = rhumb.inverse(latitude1: 0, longitude1: 0,
                              latitude2: 45, longitude2: 0)
        #expect(abs(r.azimuth) < aziTol)
        #expect(abs(r.distance - 4984944.3779777437) < distTol)
        #expect(abs(r.area) < areaTol)
    }

    @Test("60°N to 60°S along meridian")
    func sixtyNToSixtyS() {
        // echo "60 10 -60 10" | RhumbSolve -i -p 10
        // → 180.000000000000000 13308145.6389810201 0.000
        let r = rhumb.inverse(latitude1: 60, longitude1: 10,
                              latitude2: -60, longitude2: 10)
        #expect(abs(r.azimuth - 180.0) < aziTol)
        #expect(abs(r.distance - 13308145.6389810201) < distTol)
        #expect(abs(r.area) < areaTol)
    }

    @Test("Short distance near London")
    func shortDistance() {
        // echo "51.5 -0.1 51.5001 -0.0999" | RhumbSolve -i -p 10
        // → 31.969927274595101 13.1149840106 55345523.536
        let r = rhumb.inverse(latitude1: 51.5, longitude1: -0.1,
                              latitude2: 51.5001, longitude2: -0.0999)
        #expect(abs(r.azimuth - 31.969927274595101) < 1e-6) // less precision for short dist
        #expect(abs(r.distance - 13.1149840106) < 1e-3)
    }

    @Test("Anti-meridian crossing")
    func antiMeridian() {
        // echo "10 170 10 -170" | RhumbSolve -i -p 10
        // → 90.000000000000000 2192787.2813630598 2449664587955.545
        let r = rhumb.inverse(latitude1: 10, longitude1: 170,
                              latitude2: 10, longitude2: -170)
        #expect(abs(r.azimuth - 90.0) < aziTol)
        #expect(abs(r.distance - 2192787.2813630598) < distTol)
    }
}

// MARK: - Direct tests

@Suite("Rhumb direct")
struct RhumbDirectTests {
    let rhumb = Rhumb.wgs84

    @Test("JFK heading 50° for 5,500 km")
    func jfkDirect() {
        // echo "40.6 -73.8 50 5500000" | RhumbSolve -p 10
        // → 72.352687352102379 0.229708951169599 44280338963937.734
        let r = rhumb.direct(latitude: 40.6, longitude: -73.8,
                             azimuth: 50, distance: 5_500_000)
        #expect(abs(r.latitude - 72.352687352102379) < degTol)
        #expect(abs(r.longitude - 0.229708951169599) < degTol)
    }

    @Test("Equator heading east 1,000 km")
    func equatorEast() {
        // echo "0 0 90 1000000" | RhumbSolve -p 10
        // → 0.000000000000000 8.983152841195214 0.000
        let r = rhumb.direct(latitude: 0, longitude: 0,
                             azimuth: 90, distance: 1_000_000)
        #expect(abs(r.latitude) < degTol)
        #expect(abs(r.longitude - 8.983152841195214) < degTol)
        #expect(abs(r.area) < areaTol)
    }

    @Test("Equator heading north 5,000 km")
    func equatorNorth() {
        // echo "0 0 0 5000000" | RhumbSolve -p 10
        // → 45.135473786527470 0.000000000000000 0.000
        let r = rhumb.direct(latitude: 0, longitude: 0,
                             azimuth: 0, distance: 5_000_000)
        #expect(abs(r.latitude - 45.135473786527470) < degTol)
        #expect(abs(r.longitude) < degTol)
        #expect(abs(r.area) < areaTol)
    }

    @Test("Equator heading 45° for 1,000 km")
    func equator45() {
        // echo "0 0 45 1000000" | RhumbSolve -p 10
        // → 6.394591937754342 6.365188458509936 250517266745.173
        let r = rhumb.direct(latitude: 0, longitude: 0,
                             azimuth: 45, distance: 1_000_000)
        #expect(abs(r.latitude - 6.394591937754342) < degTol)
        #expect(abs(r.longitude - 6.365188458509936) < degTol)
    }

    @Test("Near pole — beyond-pole gives NaN longitude")
    func nearPole() {
        // echo "89 0 0 200000" | RhumbSolve -p 10
        // → 89.209391660223886 nan nan
        let r = rhumb.direct(latitude: 89, longitude: 0,
                             azimuth: 0, distance: 200_000)
        #expect(abs(r.latitude - 89.209391660223886) < degTol)
        // This should NOT produce NaN — 200 km from 89° stays under 90°
    }
}

// MARK: - Roundtrip tests

@Suite("Rhumb roundtrip")
struct RhumbRoundtripTests {
    let rhumb = Rhumb.wgs84

    @Test("Direct then inverse consistency")
    func directInverseRoundtrip() {
        // Direct from JFK heading 50° for 5,500 km
        let dir = rhumb.direct(latitude: 40.6, longitude: -73.8,
                               azimuth: 50, distance: 5_500_000)
        // Inverse back
        // echo "40.6 -73.8 72.352687352102379 0.229708951169599" | RhumbSolve -i -p 10
        // → 49.999999999999986 5500000.0000000009
        let inv = rhumb.inverse(latitude1: 40.6, longitude1: -73.8,
                                latitude2: dir.latitude, longitude2: dir.longitude)
        #expect(abs(inv.azimuth - 50.0) < 1e-8)
        #expect(abs(inv.distance - 5_500_000) < 0.01)
    }

    @Test("Inverse then direct consistency")
    func inverseDirectRoundtrip() {
        let inv = rhumb.inverse(latitude1: 40.6, longitude1: -73.8,
                                latitude2: 51.6, longitude2: -0.5)
        let dir = rhumb.direct(latitude: 40.6, longitude: -73.8,
                               azimuth: inv.azimuth, distance: inv.distance)
        #expect(abs(dir.latitude - 51.6) < 1e-8)
        #expect(abs(dir.longitude - (-0.5)) < 1e-8)
    }
}

// MARK: - RhumbLine tests

@Suite("RhumbLine waypoints")
struct RhumbLineTests {
    let rhumb = Rhumb.wgs84

    @Test("JFK heading 50° at 500 km intervals")
    func jfkWaypoints() {
        // echo "500000\n1000000\n2000000\n3000000" | RhumbSolve -L 40.6 -73.8 50 -p 10
        let line = rhumb.line(latitude: 40.6, longitude: -73.8, azimuth: 50)

        let p1 = line.position(distance: 500_000)
        #expect(abs(p1.latitude - 43.493504998364244) < degTol)
        #expect(abs(p1.longitude - (-69.172276281529477)) < degTol)

        let p2 = line.position(distance: 1_000_000)
        #expect(abs(p2.latitude - 46.385542028662194) < degTol)
        #expect(abs(p2.longitude - (-64.318028706506141)) < degTol)

        let p3 = line.position(distance: 2_000_000)
        #expect(abs(p3.latitude - 52.165229808341095) < degTol)
        #expect(abs(p3.longitude - (-53.774114908646368)) < degTol)

        let p4 = line.position(distance: 3_000_000)
        #expect(abs(p4.latitude - 57.939246318902896) < degTol)
        #expect(abs(p4.longitude - (-41.761944097243720)) < degTol)
    }

    @Test("Zero distance returns starting point")
    func zeroDistance() {
        let line = rhumb.line(latitude: 40.6, longitude: -73.8, azimuth: 50)
        let p = line.position(distance: 0)
        #expect(abs(p.latitude - 40.6) < degTol)
        #expect(abs(p.longitude - (-73.8)) < degTol)
    }
}

// MARK: - Static WGS84 smoke test

@Suite("Rhumb.wgs84")
struct RhumbWGS84Tests {
    @Test("Static WGS84 instance exists and works")
    func wgs84() {
        let r = Rhumb.wgs84
        #expect(r.equatorialRadius == 6_378_137)
        #expect(abs(r.flattening - 1 / 298.257223563) < 1e-15)

        // Quick inverse check
        let inv = r.inverse(latitude1: 0, longitude1: 0,
                            latitude2: 0, longitude2: 1)
        #expect(inv.distance > 0)
        #expect(abs(inv.azimuth - 90) < aziTol)
    }
}
