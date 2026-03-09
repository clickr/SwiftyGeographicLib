// Reference: echo "51.5074 -0.1278 45 48.8566 2.3522 135" | IntersectTool -c -p 17
// => -88739.97970916914346162 -335219.48014488018816337 0

import Testing
import Numerics
@testable import Intersect
import Geodesic

@Test func testIntersectClosest_greatCircleCross() {
    let inter = Intersect(geodesic: .wgs84)
    let p = inter.closest(
        latitudeX: 51.5074, longitudeX: -0.1278, azimuthX: 45,
        latitudeY: 48.8566, longitudeY: 2.3522, azimuthY: 135)
    #expect(p.x.isApproximatelyEqual(to: -88739.97970916914346162, absoluteTolerance: 0.01))
    #expect(p.y.isApproximatelyEqual(to: -335219.48014488018816337, absoluteTolerance: 0.01))
    #expect(p.c == 0)
}

