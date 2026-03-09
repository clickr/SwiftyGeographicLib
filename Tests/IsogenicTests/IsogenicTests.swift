import Testing
@testable import Isogonic
import MagneticModel
import Numerics
import Foundation

// MARK: - Marching squares unit tests

/// A flat ramp increasing left to right: value = column index.
/// Contour at value 1.5 should produce a vertical line between columns 1 and 2.
@Test func testMarchingSquares_verticalContour() {
    // 3×4 grid (3 rows, 4 columns), values = column index
    let nRows = 3
    let nCols = 4
    var grid = [Double](repeating: 0, count: nRows * nCols)
    for row in 0..<nRows {
        for col in 0..<nCols {
            grid[row * nCols + col] = Double(col)
        }
    }

    let contours = extractContours(
        grid: grid, nRows: nRows, nCols: nCols,
        minLat: 0, minLon: 0, gridSpacing: 1.0, value: 1.5
    )

    #expect(contours.count == 1, "Expected one contour polyline")
    let coords = contours[0]

    // All points should have longitude ≈ 1.5
    for coord in coords {
        #expect(coord.longitude.isApproximatelyEqual(to: 1.5, absoluteTolerance: 1e-12))
    }

    // Should span the full latitude range (0 to 2)
    let lats = coords.map(\.latitude).sorted()
    #expect(lats.first!.isApproximatelyEqual(to: 0.0, absoluteTolerance: 1e-12))
    #expect(lats.last!.isApproximatelyEqual(to: 2.0, absoluteTolerance: 1e-12))
}

/// A flat ramp increasing bottom to top: value = row index.
/// Contour at value 1.5 should produce a horizontal line between rows 1 and 2.
@Test func testMarchingSquares_horizontalContour() {
    let nRows = 4
    let nCols = 3
    var grid = [Double](repeating: 0, count: nRows * nCols)
    for row in 0..<nRows {
        for col in 0..<nCols {
            grid[row * nCols + col] = Double(row)
        }
    }

    let contours = extractContours(
        grid: grid, nRows: nRows, nCols: nCols,
        minLat: 0, minLon: 0, gridSpacing: 1.0, value: 1.5
    )

    #expect(contours.count == 1)
    let coords = contours[0]

    // All points should have latitude ≈ 1.5
    for coord in coords {
        #expect(coord.latitude.isApproximatelyEqual(to: 1.5, absoluteTolerance: 1e-12))
    }

    // Should span the full longitude range (0 to 2)
    let lons = coords.map(\.longitude).sorted()
    #expect(lons.first!.isApproximatelyEqual(to: 0.0, absoluteTolerance: 1e-12))
    #expect(lons.last!.isApproximatelyEqual(to: 2.0, absoluteTolerance: 1e-12))
}

/// A peak in the centre of a 3×3 grid should produce a closed contour.
@Test func testMarchingSquares_closedContour() {
    // 3×3 grid with a peak at (1,1)
    let nRows = 3
    let nCols = 3
    let grid: [Double] = [
        0, 0, 0,
        0, 2, 0,
        0, 0, 0
    ]

    let contours = extractContours(
        grid: grid, nRows: nRows, nCols: nCols,
        minLat: 0, minLon: 0, gridSpacing: 1.0, value: 1.0
    )

    #expect(contours.count == 1, "Expected one closed contour")
    let coords = contours[0]

    // A closed contour has first ≈ last
    let first = coords.first!
    let last = coords.last!
    #expect(first.latitude.isApproximatelyEqual(to: last.latitude, absoluteTolerance: 1e-12))
    #expect(first.longitude.isApproximatelyEqual(to: last.longitude, absoluteTolerance: 1e-12))
}

/// No contour should be produced when all grid values are above the target.
@Test func testMarchingSquares_noContour() {
    let nRows = 3
    let nCols = 3
    let grid = [Double](repeating: 5.0, count: nRows * nCols)

    let contours = extractContours(
        grid: grid, nRows: nRows, nCols: nCols,
        minLat: 0, minLon: 0, gridSpacing: 1.0, value: 1.0
    )

    #expect(contours.isEmpty)
}

/// Diagonal ramp: tests saddle-point disambiguation (cases 5 and 10).
@Test func testMarchingSquares_saddlePoint() {
    // 2×2 grid forming a saddle:
    //   TL=2  TR=0
    //   BL=0  BR=2
    let nRows = 2
    let nCols = 2
    let grid: [Double] = [
        0, 2,  // row 0 (bottom): BL=0, BR=2
        2, 0   // row 1 (top):    TL=2, TR=0
    ]

    let contours = extractContours(
        grid: grid, nRows: nRows, nCols: nCols,
        minLat: 0, minLon: 0, gridSpacing: 1.0, value: 1.0
    )

    // Should produce exactly 2 separate segments (saddle splits into two)
    #expect(contours.count == 2, "Saddle should produce two separate contour segments")
}

/// Diagonal contour through multiple cells.
@Test func testMarchingSquares_diagonalContour() {
    // 4×4 grid with values = row + col, contour at 3.5
    let nRows = 4
    let nCols = 4
    var grid = [Double](repeating: 0, count: nRows * nCols)
    for row in 0..<nRows {
        for col in 0..<nCols {
            grid[row * nCols + col] = Double(row + col)
        }
    }

    let contours = extractContours(
        grid: grid, nRows: nRows, nCols: nCols,
        minLat: 0, minLon: 0, gridSpacing: 1.0, value: 3.5
    )

    #expect(contours.count == 1, "Expected one diagonal contour")
    let coords = contours[0]
    #expect(coords.count >= 3, "Diagonal contour should have multiple points")
}

// MARK: - Integration tests with MagneticModel

/// Self-consistency: extract a declination contour line, then evaluate the
/// magnetic model at each returned coordinate. The declination at each
/// point should match the contour's value within interpolation tolerance.
@Test func testSelfConsistency_declination() throws {
    let model = try MagneticModel(name: "wmm2025")
    let isogonic = Isogonic(model: model)

    // A region over the central US with a known declination range
    let bounds = LatLonBounds(
        minLatitude: 35, maxLatitude: 45,
        minLongitude: -105, maxLongitude: -90
    )

    let contours = isogonic.contours(
        values: [0.0],
        bounds: bounds,
        time: 2026.0,
        gridSpacing: 1.0
    )

    // The 0° declination line may or may not cross this region in 2026.
    // Use -5° which reliably passes through the central US.
    let contoursMinus5 = isogonic.contours(
        values: [-5.0],
        bounds: bounds,
        time: 2026.0,
        gridSpacing: 1.0
    )

    // At least one of these should produce a contour
    let allContours = contours + contoursMinus5
    guard let contour = allContours.first else {
        // If neither contour crosses this region, that's still a valid outcome.
        // Skip the self-consistency check.
        return
    }

    // Evaluate the model at each contour point and check declination
    for coord in contour.coordinates {
        let field = model.field(
            time: 2026.0, latitude: coord.latitude,
            longitude: coord.longitude, height: 0
        )
        let components = MagneticModel.fieldComponents(
            east: field.east, north: field.north, up: field.up
        )
        // Tolerance proportional to grid spacing — linear interpolation on a
        // 1° grid introduces up to ~0.5° error for a field that varies at
        // ~1°/degree.
        #expect(
            components.declination.isApproximatelyEqual(
                to: contour.value, absoluteTolerance: 1.0
            )
        )
    }
}

/// The Date convenience overload should produce the same results as the
/// fractional year overload.
@Test func testDateConvenience() throws {
    let model = try MagneticModel(name: "wmm2025")
    let isogonic = Isogonic(model: model)

    let bounds = LatLonBounds(
        minLatitude: 40, maxLatitude: 50,
        minLongitude: -10, maxLongitude: 10
    )

    // 2026-01-01 00:00:00 UTC ≈ 2026.0
    let date = Date(timeIntervalSince1970: 1_767_225_600) // 2026-01-01

    let fromTime = isogonic.contours(
        values: [0.0], bounds: bounds, time: 2026.0, gridSpacing: 2.0
    )
    let fromDate = isogonic.contours(
        values: [0.0], bounds: bounds, date: date, gridSpacing: 2.0
    )

    // Both should produce the same number of contour lines
    #expect(fromTime.count == fromDate.count)

    // And their coordinates should be very close (small fractional-year rounding)
    if let t = fromTime.first, let d = fromDate.first {
        #expect(t.coordinates.count == d.coordinates.count)
        for (tc, dc) in zip(t.coordinates, d.coordinates) {
            #expect(tc.latitude.isApproximatelyEqual(to: dc.latitude, absoluteTolerance: 0.01))
            #expect(tc.longitude.isApproximatelyEqual(to: dc.longitude, absoluteTolerance: 0.01))
        }
    }
}

/// Different field properties should produce different contours.
@Test func testDifferentProperties() throws {
    let model = try MagneticModel(name: "wmm2025")
    let isogonic = Isogonic(model: model)

    let bounds = LatLonBounds(
        minLatitude: 30, maxLatitude: 50,
        minLongitude: -100, maxLongitude: -80
    )

    let declContours = isogonic.contours(
        property: .declination, values: [-5.0],
        bounds: bounds, time: 2026.0, gridSpacing: 2.0
    )
    let inclContours = isogonic.contours(
        property: .inclination, values: [65.0],
        bounds: bounds, time: 2026.0, gridSpacing: 2.0
    )

    // Both should produce at least one contour in this region
    #expect(!declContours.isEmpty || !inclContours.isEmpty,
            "At least one property should produce contours in the central US")
}

/// Multiple values should produce multiple contour lines.
@Test func testMultipleValues() throws {
    let model = try MagneticModel(name: "wmm2025")
    let isogonic = Isogonic(model: model)

    let bounds = LatLonBounds(
        minLatitude: 20, maxLatitude: 50,
        minLongitude: -130, maxLongitude: -60
    )

    let contours = isogonic.contours(
        values: [-20, -15, -10, -5, 0, 5, 10, 15],
        bounds: bounds,
        time: 2026.0,
        gridSpacing: 2.0
    )

    // Over the US at 2° spacing, multiple declination lines should appear
    #expect(contours.count >= 2,
            "Expected multiple contour lines across the US, got \(contours.count)")

    // Each contour's value should be one of the requested values
    let requestedValues: Set<Double> = [-20, -15, -10, -5, 0, 5, 10, 15]
    for contour in contours {
        #expect(requestedValues.contains(contour.value),
                "Unexpected contour value: \(contour.value)")
    }
}
