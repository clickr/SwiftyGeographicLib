// Reference: geocentric_gen 27.9881 86.9250 8849

import Testing
@testable import MagneticModel
import Numerics

// Tuple for array-based testing pattern:
// (lat: 27.9881, lon: 86.9250, h: 8849,
//  X: 3.02769940901197784e+05, Y: 5.63602634891839419e+06, Z: 2.97949355663691740e+06,
//  M: [-9.98560171605373359e-01, -2.51740787966156718e-02, 4.73692879426013680e-02,
//      5.36431140357016764e-02, -4.68612475152458297e-01, 8.81773646945767764e-01,
//      0.00000000000000000e+00, 8.83045080326156695e-01, 4.69288169584288095e-01]),

@Test func testGeocentricForward_everest() {
    let swiftGeo = Geocentric.wgs84
    let result = swiftGeo.intForward(lat: 27.9881, lon: 86.9250, h: 8849)
    #expect(result.X.isApproximatelyEqual(to: 3.02769940901197784e+05, absoluteTolerance: 1e-6))
    #expect(result.Y.isApproximatelyEqual(to: 5.63602634891839419e+06, absoluteTolerance: 1e-6))
    #expect(result.Z.isApproximatelyEqual(to: 2.97949355663691740e+06, absoluteTolerance: 1e-6))
    let refM = [-9.98560171605373359e-01, -2.51740787966156718e-02, 4.73692879426013680e-02,
                5.36431140357016764e-02, -4.68612475152458297e-01, 8.81773646945767764e-01,
                0.00000000000000000e+00, 8.83045080326156695e-01, 4.69288169584288095e-01]
    for i in 0..<9 {
        #expect(result.M[i].isApproximatelyEqual(to: refM[i], absoluteTolerance: 1e-12))
    }
}

