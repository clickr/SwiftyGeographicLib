// MARK: - Types

/// Identifies which edge of a grid cell a contour crosses.
internal enum Edge: Int, Sendable {
    case bottom = 0  // between (i, j) and (i, j+1)
    case right  = 1  // between (i, j+1) and (i+1, j+1)
    case top    = 2  // between (i+1, j) and (i+1, j+1)
    case left   = 3  // between (i, j) and (i+1, j)
}

/// A unique identifier for a contour crossing point on a grid edge.
///
/// Two segments share a crossing point when they reference the same
/// grid edge — e.g. cell (i, j)'s top edge is cell (i+1, j)'s bottom edge.
/// The canonical form uses the bottom/left edge of the appropriate cell.
internal struct GridPoint: Hashable, Sendable {
    let row: Int
    let col: Int
    let edge: Edge
}

/// A line segment produced by a single grid cell, connecting two edge crossings.
internal struct Segment: Sendable {
    let startKey: GridPoint
    let startLat: Double
    let startLon: Double
    let endKey: GridPoint
    let endLat: Double
    let endLon: Double
}

// MARK: - Contour extraction

/// Extracts contour lines from a scalar field sampled on a regular lat/lon grid.
///
/// - Parameters:
///   - grid: Row-major array of scalar values, size `nRows * nCols`.
///   - nRows: Number of latitude steps (grid rows).
///   - nCols: Number of longitude steps (grid columns).
///   - minLat: Latitude at row 0.
///   - minLon: Longitude at column 0.
///   - gridSpacing: Distance between adjacent grid nodes in degrees.
///   - value: The target contour value to trace.
/// - Returns: An array of coordinate sequences, one per contour polyline.
internal func extractContours(
    grid: [Double],
    nRows: Int,
    nCols: Int,
    minLat: Double,
    minLon: Double,
    gridSpacing: Double,
    value: Double
) -> [[(latitude: Double, longitude: Double)]] {
    let segments = generateSegments(
        grid: grid, nRows: nRows, nCols: nCols,
        minLat: minLat, minLon: minLon,
        gridSpacing: gridSpacing, value: value
    )
    return assemblePolylines(from: segments)
}

// MARK: - Segment generation

/// Generates contour segments for every grid cell using marching squares.
private func generateSegments(
    grid: [Double],
    nRows: Int,
    nCols: Int,
    minLat: Double,
    minLon: Double,
    gridSpacing: Double,
    value: Double
) -> [Segment] {
    var segments: [Segment] = []

    // Perturb grid values that exactly equal the target to avoid
    // degenerate cases where a contour passes through a grid node.
    var g = grid
    let eps = 1e-10
    for i in 0..<g.count {
        if g[i] == value { g[i] += eps }
    }

    for row in 0..<(nRows - 1) {
        for col in 0..<(nCols - 1) {
            // Cell corners (counter-clockwise from bottom-left):
            //   BL = (row, col)      BR = (row, col+1)
            //   TL = (row+1, col)    TR = (row+1, col+1)
            let bl = g[row * nCols + col]
            let br = g[row * nCols + col + 1]
            let tl = g[(row + 1) * nCols + col]
            let tr = g[(row + 1) * nCols + col + 1]

            // 4-bit case: bit 0 = BL, bit 1 = BR, bit 2 = TR, bit 3 = TL
            var caseIndex = 0
            if bl > value { caseIndex |= 1 }
            if br > value { caseIndex |= 2 }
            if tr > value { caseIndex |= 4 }
            if tl > value { caseIndex |= 8 }

            if caseIndex == 0 || caseIndex == 15 { continue }

            let latBottom = minLat + Double(row) * gridSpacing
            let latTop    = minLat + Double(row + 1) * gridSpacing
            let lonLeft   = minLon + Double(col) * gridSpacing
            let lonRight  = minLon + Double(col + 1) * gridSpacing

            // Interpolated crossing points on each edge
            func bottomCrossing() -> (Double, Double, GridPoint) {
                let lon = interpolate(v1: bl, v2: br, p1: lonLeft, p2: lonRight, target: value)
                return (latBottom, lon, canonicalKey(row: row, col: col, edge: .bottom))
            }
            func rightCrossing() -> (Double, Double, GridPoint) {
                let lat = interpolate(v1: br, v2: tr, p1: latBottom, p2: latTop, target: value)
                return (lat, lonRight, canonicalKey(row: row, col: col, edge: .right))
            }
            func topCrossing() -> (Double, Double, GridPoint) {
                let lon = interpolate(v1: tl, v2: tr, p1: lonLeft, p2: lonRight, target: value)
                return (latTop, lon, canonicalKey(row: row, col: col, edge: .top))
            }
            func leftCrossing() -> (Double, Double, GridPoint) {
                let lat = interpolate(v1: bl, v2: tl, p1: latBottom, p2: latTop, target: value)
                return (lat, lonLeft, canonicalKey(row: row, col: col, edge: .left))
            }

            func addSegment(
                _ a: (Double, Double, GridPoint),
                _ b: (Double, Double, GridPoint)
            ) {
                segments.append(Segment(
                    startKey: a.2, startLat: a.0, startLon: a.1,
                    endKey: b.2, endLat: b.0, endLon: b.1
                ))
            }

            switch caseIndex {
            case 1:  addSegment(bottomCrossing(), leftCrossing())
            case 2:  addSegment(bottomCrossing(), rightCrossing())
            case 3:  addSegment(leftCrossing(), rightCrossing())
            case 4:  addSegment(rightCrossing(), topCrossing())
            case 5:  // Saddle: disambiguate using cell-centre value
                let centre = (bl + br + tl + tr) / 4
                if centre > value {
                    addSegment(bottomCrossing(), rightCrossing())
                    addSegment(leftCrossing(), topCrossing())
                } else {
                    addSegment(bottomCrossing(), leftCrossing())
                    addSegment(rightCrossing(), topCrossing())
                }
            case 6:  addSegment(bottomCrossing(), topCrossing())
            case 7:  addSegment(leftCrossing(), topCrossing())
            case 8:  addSegment(leftCrossing(), topCrossing())
            case 9:  addSegment(bottomCrossing(), topCrossing())
            case 10: // Saddle: disambiguate using cell-centre value
                let centre = (bl + br + tl + tr) / 4
                if centre > value {
                    addSegment(leftCrossing(), topCrossing())
                    addSegment(bottomCrossing(), rightCrossing())
                } else {
                    addSegment(leftCrossing(), bottomCrossing())
                    addSegment(topCrossing(), rightCrossing())
                }
            case 11: addSegment(rightCrossing(), topCrossing())
            case 12: addSegment(leftCrossing(), rightCrossing())
            case 13: addSegment(bottomCrossing(), rightCrossing())
            case 14: addSegment(bottomCrossing(), leftCrossing())
            default: break
            }
        }
    }

    return segments
}

// MARK: - Edge canonicalisation

/// Returns the canonical key for an edge crossing.
///
/// Shared edges between adjacent cells are mapped to the same key:
/// - A cell's **top** edge is the cell above's **bottom** edge.
/// - A cell's **right** edge is the cell to the right's **left** edge.
private func canonicalKey(row: Int, col: Int, edge: Edge) -> GridPoint {
    switch edge {
    case .bottom: return GridPoint(row: row, col: col, edge: .bottom)
    case .top:    return GridPoint(row: row + 1, col: col, edge: .bottom)
    case .left:   return GridPoint(row: row, col: col, edge: .left)
    case .right:  return GridPoint(row: row, col: col + 1, edge: .left)
    }
}

// MARK: - Interpolation

/// Linearly interpolates between two positions to find where the field
/// equals the target value.
private func interpolate(
    v1: Double, v2: Double,
    p1: Double, p2: Double,
    target: Double
) -> Double {
    let t = (target - v1) / (v2 - v1)
    return p1 + t * (p2 - p1)
}

// MARK: - Polyline assembly

/// Chains segments into ordered polylines by matching shared edge crossings.
private func assemblePolylines(
    from segments: [Segment]
) -> [[(latitude: Double, longitude: Double)]] {
    guard !segments.isEmpty else { return [] }

    // Build adjacency: for each grid-point key, record which segment
    // indices touch it.
    var adjacency: [GridPoint: [Int]] = [:]
    for (i, seg) in segments.enumerated() {
        adjacency[seg.startKey, default: []].append(i)
        adjacency[seg.endKey, default: []].append(i)
    }

    var used = [Bool](repeating: false, count: segments.count)
    var polylines: [[(latitude: Double, longitude: Double)]] = []

    for startIndex in 0..<segments.count {
        guard !used[startIndex] else { continue }
        used[startIndex] = true

        let first = segments[startIndex]
        var coords: [(latitude: Double, longitude: Double)] = [
            (first.startLat, first.startLon),
            (first.endLat, first.endLon)
        ]
        var frontKey = first.startKey
        var backKey = first.endKey

        // Extend backward from the front
        while true {
            guard let next = findUnused(adjacentTo: frontKey, in: adjacency, used: &used, segments: segments) else { break }
            let seg = segments[next]
            if seg.endKey == frontKey {
                coords.insert((seg.startLat, seg.startLon), at: 0)
                frontKey = seg.startKey
            } else {
                coords.insert((seg.endLat, seg.endLon), at: 0)
                frontKey = seg.endKey
            }
        }

        // Extend forward from the back
        while true {
            guard let next = findUnused(adjacentTo: backKey, in: adjacency, used: &used, segments: segments) else { break }
            let seg = segments[next]
            if seg.startKey == backKey {
                coords.append((seg.endLat, seg.endLon))
                backKey = seg.endKey
            } else {
                coords.append((seg.startLat, seg.startLon))
                backKey = seg.startKey
            }
        }

        polylines.append(coords)
    }

    return polylines
}

/// Finds an unused segment adjacent to the given grid-point key.
private func findUnused(
    adjacentTo key: GridPoint,
    in adjacency: [GridPoint: [Int]],
    used: inout [Bool],
    segments: [Segment]
) -> Int? {
    guard let candidates = adjacency[key] else { return nil }
    for idx in candidates {
        guard !used[idx] else { continue }
        used[idx] = true
        return idx
    }
    return nil
}
