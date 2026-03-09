// Reference: echo -89.0 0.0 | GeoConvert -u -p 9
// s 2000000.000000000 2111026.520119314
// Convergence and scale: -0.0000000000000 0.994075701194405

import Testing
@testable import PolarStereographic
import CoreLocation
import Numerics

@Test func testPolarStereographicForward_southPole() {
    let coord: CLLocationCoordinate2D = .init(latitude: -89.0, longitude: 0.0)
    let forward = PolarStereographic.UPS.forward(coordinate: coord)
    #expect(forward.northp == false)
    #expect((forward.x + 20e5).isApproximatelyEqual(to: 2000000.000000000, absoluteTolerance: 1e-9))
    #expect((forward.y + 20e5).isApproximatelyEqual(to: 2111026.520119314, absoluteTolerance: 1e-9))
    #expect(forward.convergence.isApproximatelyEqual(to: -0.0000000000000, absoluteTolerance: 1e-9))
    #expect(forward.centralScale.isApproximatelyEqual(to: 0.994075701194405, absoluteTolerance: 1e-9))
}

@Test func testPolarStereographicReverse_southPole() {
    let x = 2000000.000000000 - 20e5
    let y = 2111026.520119314 - 20e5
    let reverse = PolarStereographic.UPS.reverse(northp: false, x: x, y: y)
    #expect(reverse.coordinate.latitude.isApproximatelyEqual(to: -89.0, absoluteTolerance: 1e-6))
    #expect(reverse.coordinate.longitude.isApproximatelyEqual(to: 0.0, absoluteTolerance: 1e-6))
}

