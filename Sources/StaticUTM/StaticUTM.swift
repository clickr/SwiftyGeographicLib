//
//  StaticUTM.swift
//  SwiftGeoLib
//
//  Created by David Hart on 7/3/2026.
//


import Foundation
import TransverseMercatorStatic
import CoreLocation

/// A statically configured transverse Mercator projection using WGS84 ellipsoid parameters.
///
/// `StaticUTM` wraps `InternalUTM`, a concrete conformance of ``TransverseMercatorStaticInternal``
/// pre-computed for the WGS84 datum (equatorial radius 6378137 m, flattening 1/298.257223563,
/// central scale factor 0.9996). Because all ellipsoid constants are stored as static `let`
/// properties at compile time, repeated projections avoid the setup cost paid by the dynamic
/// ``TransverseMercator`` type.
///
/// ## Usage
/// ```swift
/// let lon0 = centralMeridian(zone: 50)
/// let coord = CLLocationCoordinate2D(latitude: 31.9398, longitude: 115.9665)
/// let (x, y, convergence, scale) = StaticUTM.forward(centralMeridian: lon0,
///                                                     geodeticCoordinate: coord)
/// let (back, γ, k) = StaticUTM.reverse(centralMeridian: lon0, x: x, y: y)
/// ```
///
/// - SeeAlso: ``TransverseMercatorStaticInternal``
public struct StaticUTM {
    /// Forward projection, from geographic to transverse Mercator.
    ///
    /// Converts a geographic coordinate (latitude and longitude) to transverse Mercator
    /// projection coordinates (easting, northing).
    ///
    /// This implementation uses Krüger's method with a 6th-order series approximation,
    /// providing accuracy of about 5 nanometers within 35 degrees of the central meridian.
    ///
    /// - Parameters:
    ///   - centralMeridian: The central meridian of the projection in degrees.
    ///     This is the longitude at which the projection has no distortion.
    ///   - geodeticCoordinate: The geographic coordinate to convert.
    ///
    /// - Returns: A tuple containing:
    ///   - x: The easting of the point in meters.
    ///   - y: The northing of the point in meters.
    ///   - convergence: The meridian convergence at the point in degrees. This is
    ///     the angle between grid north and true north.
    ///   - centralScale: The scale factor of the projection at the point.
    ///
    /// - Note: No false easting or false northing is added. The latitude should
    ///   be in the range [-90°, 90°].
    ///
    /// - SeeAlso: ``reverse(centralMeridian:x:y:)``
    public static func forward(centralMeridian: Double, geodeticCoordinate: CLLocationCoordinate2D) -> (x: Double, y: Double, convergence: Double, centralScale: Double) {
        return InternalUTM.forward(centralMeridian: centralMeridian, geodeticCoordinate: geodeticCoordinate)
    }

    /// Forward projection, from geographic to transverse Mercator.
    ///
    /// Convenience overload that accepts separate latitude and longitude values instead of
    /// a `CLLocationCoordinate2D`. See ``forward(centralMeridian:geodeticCoordinate:)`` for
    /// full parameter and return-value documentation.
    ///
    /// - Parameters:
    ///   - centralMeridian: The central meridian of the projection in degrees.
    ///   - latitude: Geodetic latitude in degrees. Should be in the range [-90°, 90°].
    ///   - longitude: Longitude in degrees.
    ///
    /// - SeeAlso: ``forward(centralMeridian:geodeticCoordinate:)``
    static func forward(centralMeridian: Double, latitude: Double, longitude: Double) -> (x: Double, y: Double, convergence: Double, centralScale: Double) {
        return forward(centralMeridian: centralMeridian, geodeticCoordinate: .init(latitude: latitude, longitude: longitude))
    }

    /// Reverse projection, from transverse Mercator to geographic.
    ///
    /// Converts transverse Mercator projection coordinates (easting, northing) back to
    /// geographic coordinates (latitude, longitude).
    ///
    /// This implementation uses Krüger's method with a 6th-order series approximation,
    /// providing accuracy of about 5 nanometers within 35 degrees of the central meridian.
    ///
    /// - Parameters:
    ///   - centralMeridian: The central meridian of the projection in degrees.
    ///     This is the longitude at which the projection has no distortion.
    ///   - x: The easting of the point in meters.
    ///   - y: The northing of the point in meters.
    ///
    /// - Returns: A tuple containing:
    ///   - coordinate: The geographic coordinate (latitude and longitude in degrees).
    ///   - convergence: The meridian convergence at the point in degrees. This is
    ///     the angle between grid north and true north.
    ///   - centralScale: The scale factor of the projection at the point.
    ///
    /// - Note: No false easting or false northing is added. The longitude returned
    ///   is in the range [-180°, 180°].
    ///
    /// - SeeAlso: ``forward(centralMeridian:geodeticCoordinate:)``
    public static func reverse(centralMeridian: Double,
                        x: Double,
                        y: Double) -> (coordinate: CLLocationCoordinate2D, convergence: Double, centralScale: Double) {
        return InternalUTM.reverse(centralMeridian: centralMeridian, x: x, y: y)
    }

    /// The equatorial radius of the WGS84 ellipsoid in meters (6378137.0 m).
    public static var equatorialRadius: Double {
        return InternalUTM.EquatorialRadius
    }

    /// The flattening of the WGS84 ellipsoid (1/298.257223563).
    public static var flattening: Double {
        return InternalUTM.Flattening
    }

    /// The central scale factor applied along the central meridian (0.9996 for UTM).
    public static var centralScale: Double {
        return InternalUTM.CentralScale
    }
}
