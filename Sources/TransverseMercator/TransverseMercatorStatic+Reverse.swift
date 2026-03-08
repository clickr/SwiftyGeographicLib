//
//  Reverse.swift
//  SwiftGeoLib
//
//  Created by David Hart on 6/3/2026.
//
import Foundation
import CoreLocation
import ComplexModule
import Math

public extension TransverseMercatorStaticProtocol {
    /// Reverse projection, from transverse Mercator to geographic.
    ///
    /// This function converts transverse Mercator projection coordinates (easting,
    /// northing) back to geographic coordinates (latitude, longitude).
    ///
    /// The transverse Mercator projection is a conformal map projection that
    /// stretches the sphere along a central meridian. This implementation uses
    /// Krüger's method with a 6th order series approximation, providing accuracy
    /// of about 5 nanometers within 35 degrees of the central meridian.
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
    static func reverse(centralMeridian: Double,
                        x: Double,
                        y: Double) -> (coordinate: CLLocationCoordinate2D, convergence: Double, centralScale: Double) {
        return _reverse(centralMeridian: centralMeridian, x: x, y: y,
                                                         centralScale: centralScale,
                                                         _e2: _e2,
                                                         _es: _es,
                                                         _e2m: _e2m,
                                                         _c: _c,
                                                         _b1: _b1,
                                                         _a1: _a1,
                                                         _bet: _bet)
    }
}
