// Reference: echo "64.1466 -21.9426 0" | MagneticField -n wmm2025 -t 2025.0 -r -p 15

import Testing
import Foundation
@testable import MagneticModel
import Numerics

// Tuple for array-based testing pattern:
// (t: 2025.0, lat: 64.1466, lon: -21.9426, h: 0,
//  east: -2653.1445843928, north: 12945.1800361146, up: -5.087608172547400e+04,
//  eastDeltaT: 65.2102353767, northDeltaT: 25.2015225580, upDeltaT: -1.096705271230000e+01),

@Test func testWMM2025Field_reykjavik() throws {
    let model = try MagneticModel(name: "wmm2025")
    let result = model.fieldWithRates(
        time: 2025.0, latitude: 64.1466,
        longitude: -21.9426, height: 0)
    let tol = 1e-6
    #expect(result.field.east.isApproximatelyEqual(to: -2653.1445843928, absoluteTolerance: tol))
    #expect(result.field.north.isApproximatelyEqual(to: 12945.1800361146, absoluteTolerance: tol))
    #expect(result.field.up.isApproximatelyEqual(to: -5.087608172547400e+04, absoluteTolerance: tol))
    #expect(result.eastDeltaT.isApproximatelyEqual(to: 65.2102353767, absoluteTolerance: tol))
    #expect(result.northDeltaT.isApproximatelyEqual(to: 25.2015225580, absoluteTolerance: tol))
    #expect(result.upDeltaT.isApproximatelyEqual(to: -1.096705271230000e+01, absoluteTolerance: tol))
}

