// WGS 60 ellipsoid — the first World Geodetic System (1960).
// Developed by the U.S. Department of Defense combining surface gravity,
// astro-geodetic data, and early satellite observations.
//   a = 6,378,165 m     1/f = 298.3
//
// Test location: Washington D.C. (38.8977°N, 77.0365°W)
// Reference: tm_gen 6378165.0 3.35232986925913497e-03 0.9996 -75 38.8977 -77.0365

import Testing
@testable import TransverseMercator
import Numerics
import Ellipsoid

@Test func testTransverseMercatorCustomForward_wgs60WashingtonDC() throws {
    let tm = try TransverseMercator(
        ellipsoid: .wgs60,
        scaleFactor: 0.9996)
    let forward = tm.forward(centralMeridian: -75, latitude: 38.8977, longitude: -77.0365)
    #expect(forward.x.isApproximatelyEqual(to: -1.76606445416749833e+05, absoluteTolerance: 1e-9))
    #expect(forward.y.isApproximatelyEqual(to: 4.30741782763011660e+06, absoluteTolerance: 1e-9))
    #expect(forward.convergence.isApproximatelyEqual(to: -1.27911339792738188e+00, absoluteTolerance: 1e-9))
    #expect(forward.centralScale.isApproximatelyEqual(to: 9.99984072416959413e-01, absoluteTolerance: 1e-9))
}

@Test func testTransverseMercatorCustomReverse_wgs60WashingtonDC() throws {
    let tm = try TransverseMercator(
        ellipsoid: .wgs60,
        scaleFactor: 0.9996)
    let reverse = tm.reverse(centralMeridian: -75, x: -1.76606445416749833e+05, y: 4.30741782763011660e+06)
    #expect(reverse.coordinate.latitude.isApproximatelyEqual(to: 38.8977, absoluteTolerance: 1e-9))
    #expect(reverse.coordinate.longitude.isApproximatelyEqual(to: -77.0365, absoluteTolerance: 1e-9))
    #expect(reverse.convergence.isApproximatelyEqual(to: -1.27911339792738188e+00, absoluteTolerance: 1e-9))
    #expect(reverse.centralScale.isApproximatelyEqual(to: 9.99984072416959413e-01, absoluteTolerance: 1e-9))
}
