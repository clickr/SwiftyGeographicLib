// Reference: echo 85.0 15.0 | GeoConvert -u -p 9
// n 2143762.951632802 1463469.360260316
// Convergence and scale: 15.0000000000000 0.995894791674975

import Testing
@testable import UPS
import Numerics
import CoreLocation

@Test func testUPSForward_svalbard() throws {
    let ups = try UPS(latitude: 85.0, longitude: 15.0)
    #expect(ups.hemisphere == .northern)
    #expect(ups.easting.isApproximatelyEqual(to: 2143762.951632802, absoluteTolerance: 1e-9))
    #expect(ups.northing.isApproximatelyEqual(to: 1463469.360260316, absoluteTolerance: 1e-9))
    #expect(ups.convergence.isApproximatelyEqual(to: 15.0000000000000, absoluteTolerance: 1e-9))
    #expect(ups.centralScale.isApproximatelyEqual(to: 0.995894791674975, absoluteTolerance: 1e-9))
}

@Test func testUPSReverse_svalbard() throws {
    let ups = try UPS(hemisphere: .northern, easting: 2143762.951632802, northing: 1463469.360260316)
    #expect(ups.geodeticCoordinate.latitude.isApproximatelyEqual(to: 85.0, absoluteTolerance: 1e-6))
    #expect(ups.geodeticCoordinate.longitude.isApproximatelyEqual(to: 15.0, absoluteTolerance: 1e-6))
}

