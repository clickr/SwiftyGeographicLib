//
//  GeodesicResult.swift
//  SwiftGeoLib
//
//  Created by David Hart on 7/3/2026.
//

import Foundation

/// The result of a geodesic direct problem.
///
/// Returned by `Geodesic.direct(...)` and `Geodesic.arcDirect(...)`.
/// Contains the destination position, arrival azimuth, and the arc-length
/// (spherical arc in degrees) of the geodesic.
///
/// Corresponds to the output parameters of `Geodesic::Direct` /
/// `Geodesic::GenDirect` in the GeographicLib C++ API.
public struct GeodesicDirectResult: Sendable {
    /// Latitude of the destination point in degrees.
    public let latitude: Double
    /// Longitude of the destination point in degrees.
    public let longitude: Double
    /// Azimuth at the destination point in degrees (−180°, 180°].
    public let azimuth: Double
    /// Distance from point 1 to point 2 in metres (always computed).
    public let distance: Double
    /// Arc length of the geodesic on the auxiliary sphere in degrees.
    ///
    /// Corresponds to `a12` in the GeographicLib C++ API.
    public let arcLength: Double
    /// Reduced length of the geodesic in metres, if computed.
    ///
    /// Corresponds to `m12` in the GeographicLib C++ API.
    public let reducedLength: Double?
    /// Geodesic scale of point 2 relative to point 1, if computed.
    ///
    /// Corresponds to `M12` in the GeographicLib C++ API.
    public let geodesicScale12: Double?
    /// Geodesic scale of point 1 relative to point 2, if computed.
    ///
    /// Corresponds to `M21` in the GeographicLib C++ API.
    public let geodesicScale21: Double?
}

/// The result of a geodesic inverse problem.
///
/// Returned by `Geodesic.inverse(...)`.
/// Contains the distance between the two points and the azimuths at each end.
///
/// Corresponds to the output parameters of `Geodesic::Inverse` /
/// `Geodesic::GenInverse` in the GeographicLib C++ API.
public struct GeodesicInverseResult: Sendable {
    /// Distance from point 1 to point 2 in metres.
    public let distance: Double
    /// Azimuth at point 1 in degrees (−180°, 180°].
    public let azimuth1: Double
    /// Azimuth at point 2 in degrees (−180°, 180°].
    public let azimuth2: Double
    /// Arc length of the geodesic on the auxiliary sphere in degrees.
    ///
    /// Corresponds to `a12` in the GeographicLib C++ API.
    public let arcLength: Double
    /// Reduced length of the geodesic in metres, if computed.
    ///
    /// Corresponds to `m12` in the GeographicLib C++ API.
    public let reducedLength: Double?
    /// Geodesic scale of point 2 relative to point 1, if computed.
    public let geodesicScale12: Double?
    /// Geodesic scale of point 1 relative to point 2, if computed.
    public let geodesicScale21: Double?
}

/// The result of evaluating a position on a `GeodesicLine`.
///
/// Returned by `GeodesicLine.position(distance:)` and
/// `GeodesicLine.arcPosition(arcLength:)`.
///
/// Corresponds to the output parameters of `GeodesicLine::Position` /
/// `GeodesicLine::GenPosition` in the GeographicLib C++ API.
public struct GeodesicPosition: Sendable {
    /// Latitude of the point in degrees.
    public let latitude: Double
    /// Longitude of the point in degrees.
    public let longitude: Double
    /// Azimuth at the point in degrees (−180°, 180°].
    public let azimuth: Double
    /// Distance from the origin of the line in metres.
    public let distance: Double
    /// Arc length from the origin of the line on the auxiliary sphere in degrees.
    ///
    /// Corresponds to `a12` in the GeographicLib C++ API.
    public let arcLength: Double
    /// Reduced length of the geodesic segment in metres, if computed.
    public let reducedLength: Double?
    /// Geodesic scale, if computed.
    public let geodesicScale12: Double?
    /// Geodesic scale (reverse), if computed.
    public let geodesicScale21: Double?
}
