//
//  TransverseMercator+Forward.swift
//  SwiftGeoLib
//
//  Created by David Hart on 6/3/2026.
//


import Foundation
import CoreLocation
import ComplexModule
import Math

public extension TransverseMercator {
    /// Forward projection, from geographic to transverse Mercator.
    ///
    /// This function converts a geographic coordinate (latitude and longitude) to
    /// transverse Mercator projection coordinates (easting, northing).
    ///
    /// The transverse Mercator projection is a conformal map projection that
    /// stretches the sphere along a central meridian. This implementation uses
    /// Krüger's method with a 6th order series approximation, providing accuracy
    /// of about 5 nanometers within 35 degrees of the central meridian.
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
    func forward(centralMeridian: Double, geodeticCoordinate: CLLocationCoordinate2D) -> (x: Double, y: Double, convergence: Double, centralScale: Double) {
        return _forward(centralMeridian: centralMeridian, geodeticCoordinate: geodeticCoordinate,
                                                         centralScale: centralScale,
                                                         _e2: e2,
                                                         _es: es,
                                                         _e2m: e2m,
                                                         _c: c,
                                                         _b1: b1,
                                                         _a1: a1,
                                                         _alp: alp)
    }
}
