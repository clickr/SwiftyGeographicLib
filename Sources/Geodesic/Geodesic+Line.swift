//
//  Geodesic+Line.swift
//  SwiftGeoLib
//
//  Created by David Hart on 7/3/2026.
//

import Foundation
import Math

public extension Geodesic {

    // MARK: - GeodesicLine factory methods

    /// Create a `GeodesicLine` from a starting point and azimuth.
    ///
    /// - Parameters:
    ///   - latitude: Latitude of the starting point in degrees (−90° to 90°).
    ///   - longitude: Longitude of the starting point in degrees.
    ///   - azimuth: Azimuth at the starting point in degrees (−180° to 180°].
    /// - Returns: A `GeodesicLine` ready for position queries.
    func line(latitude: Double, longitude: Double, azimuth: Double) -> GeodesicLine {
        return GeodesicLine(geodesic: self, lat1: latitude, lon1: longitude, azi1: azimuth)
    }

    /// Create a `GeodesicLine` that coincides with the direct geodesic to the
    /// given distance.
    ///
    /// Equivalent to `line(...)` but pre-sets the end-point distance on the
    /// line so that `GeodesicLine.position(distance:)` can be called with
    /// fractions of `distance`.
    ///
    /// Corresponds to `Geodesic::DirectLine` in the C++ API.
    func directLine(latitude: Double, longitude: Double,
                    azimuth: Double, distance: Double) -> GeodesicLine {
        return genDirectLine(lat1: latitude, lon1: longitude, azi1: azimuth,
                             arcmode: false, s12a12: distance)
    }

    /// Create a `GeodesicLine` that coincides with the direct geodesic to the
    /// given arc length.
    ///
    /// Corresponds to `Geodesic::ArcDirectLine` in the C++ API.
    func arcDirectLine(latitude: Double, longitude: Double,
                       azimuth: Double, arcLength: Double) -> GeodesicLine {
        return genDirectLine(lat1: latitude, lon1: longitude, azi1: azimuth,
                             arcmode: true, s12a12: arcLength)
    }

    /// Create a `GeodesicLine` along the inverse geodesic from point 1 to
    /// point 2.
    ///
    /// Corresponds to `Geodesic::InverseLine` in the C++ API.
    func inverseLine(latitude1: Double, longitude1: Double,
                     latitude2: Double, longitude2: Double) -> GeodesicLine {
        var salp1 = 0.0, calp1 = 0.0, salp2 = 0.0, calp2 = 0.0
        var s12 = 0.0, m12 = 0.0, M12 = 0.0, M21 = 0.0
        _ = genInverse(lat1: latitude1, lon1: longitude1,
                       lat2: latitude2, lon2: longitude2,
                       s12: &s12,
                       salp1: &salp1, calp1: &calp1,
                       salp2: &salp2, calp2: &calp2,
                       m12: &m12, M12: &M12, M21: &M21)
        let azi1 = atan2d(salp1, calp1)
        return GeodesicLine(geodesic: self, lat1: latitude1, lon1: longitude1,
                            azi1: azi1, salp1: salp1, calp1: calp1)
    }

    // MARK: - Internal generic direct-line factory

    internal func genDirectLine(lat1: Double, lon1: Double, azi1: Double,
                                 arcmode: Bool, s12a12: Double) -> GeodesicLine {
        let azi = angNormalize(azi1)
        let (salp, calp) = sincosd(degrees: angRound(azi))
        return GeodesicLine(geodesic: self, lat1: lat1, lon1: lon1, azi1: azi,
                            salp1: salp, calp1: calp)
    }
}
