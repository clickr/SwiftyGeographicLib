//
//  Geodesic+Direct.swift
//  SwiftGeoLib
//
//  Created by David Hart on 7/3/2026.
//

import Foundation
import Math

public extension Geodesic {

    // MARK: - Public direct API

    /// Solve the direct geodesic problem.
    ///
    /// Given a starting point, an azimuth, and a distance, find the
    /// destination point and arrival azimuth.
    ///
    /// - Parameters:
    ///   - latitude: Latitude of point 1 in degrees (−90° to 90°).
    ///   - longitude: Longitude of point 1 in degrees.
    ///   - azimuth: Azimuth at point 1 in degrees (−180° to 180°].
    ///   - distance: Distance from point 1 to point 2 in metres.
    /// - Returns: `GeodesicDirectResult` with destination and arrival azimuth.
    func direct(latitude: Double, longitude: Double,
                azimuth: Double, distance: Double) -> GeodesicDirectResult {
        let a12 = genDirect(lat1: latitude, lon1: longitude, azi1: azimuth,
                            arcmode: false, s12a12: distance)
        return a12
    }

    /// Solve the direct geodesic problem using arc length.
    ///
    /// Like `direct(...)` but the parameter is the arc length on the auxiliary
    /// sphere in degrees rather than metric distance.
    ///
    /// - Parameters:
    ///   - latitude: Latitude of point 1 in degrees.
    ///   - longitude: Longitude of point 1 in degrees.
    ///   - azimuth: Azimuth at point 1 in degrees.
    ///   - arcLength: Arc length from point 1 to point 2 in degrees.
    /// - Returns: `GeodesicDirectResult` with destination and arrival azimuth.
    func arcDirect(latitude: Double, longitude: Double,
                   azimuth: Double, arcLength: Double) -> GeodesicDirectResult {
        return genDirect(lat1: latitude, lon1: longitude, azi1: azimuth,
                         arcmode: true, s12a12: arcLength)
    }

    // MARK: - Internal generic direct

    /// Internal generic direct problem (distance or arc mode).
    ///
    /// Creates a `GeodesicLine` at the starting point and calls `genPosition`.
    /// Corresponds to `Geodesic::GenDirect` in the C++ API.
    internal func genDirect(lat1: Double, lon1: Double, azi1: Double,
                             arcmode: Bool, s12a12: Double) -> GeodesicDirectResult {
        let line = GeodesicLine(geodesic: self, lat1: lat1, lon1: lon1, azi1: azi1)
        let p = line.genPosition(arcmode: arcmode, s12a12: s12a12)
        return GeodesicDirectResult(
            latitude: p.latitude,
            longitude: p.longitude,
            azimuth: p.azimuth,
            distance: p.distance,
            arcLength: p.arcLength,
            reducedLength: p.reducedLength,
            geodesicScale12: p.geodesicScale12,
            geodesicScale21: p.geodesicScale21)
    }
}
