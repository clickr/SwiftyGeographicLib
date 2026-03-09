// Reference: echo 35.6762 139.6503 | GeoConvert -u -s -p 9
// 54n 377855.775951768 3948874.392162377
// Convergence and scale: -0.7872475854721 0.999783845026535

import Testing
@testable import TransverseMercator
import Math
import Numerics
import CoreLocation

// utmFalseEasting and utmNorthShift are declared in TransverseMercatorTests.swift

@Test func testTransverseMercatorForward_tokyo() {
    let lon0 = centralMeridian(zone: 54)
    let forward = TransverseMercator.UTM.forward(centralMeridian: lon0, latitude: 35.6762, longitude: 139.6503)
    #expect((forward.x + utmFalseEasting).isApproximatelyEqual(to: 377855.775951768, absoluteTolerance: 1e-9))
    #expect(forward.y.isApproximatelyEqual(to: 3948874.392162377, absoluteTolerance: 1e-9))
    #expect(forward.convergence.isApproximatelyEqual(to: -0.7872475854721, absoluteTolerance: 1e-9))
    #expect(forward.centralScale.isApproximatelyEqual(to: 0.999783845026535, absoluteTolerance: 1e-9))
}

@Test func testTransverseMercatorReverse_tokyo() {
    let lon0 = centralMeridian(zone: 54)
    let reverse = TransverseMercator.UTM.reverse(centralMeridian: lon0, x: 377855.775951768 - utmFalseEasting, y: 3948874.392162377)
    #expect(reverse.coordinate.latitude.isApproximatelyEqual(to: 35.6762, absoluteTolerance: 1e-9))
    #expect(reverse.coordinate.longitude.isApproximatelyEqual(to: 139.6503, absoluteTolerance: 1e-9))
    #expect(reverse.convergence.isApproximatelyEqual(to: -0.7872475854721, absoluteTolerance: 1e-9))
    #expect(reverse.centralScale.isApproximatelyEqual(to: 0.999783845026535, absoluteTolerance: 1e-9))
}

