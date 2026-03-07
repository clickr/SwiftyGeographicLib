//
//  StaticUTM.swift
//  SwiftGeoLib
//
//  Created by David Hart on 7/3/2026.
//


import Foundation
import TransverseMercatorStatic
import CoreLocation

public struct StaticUTM {
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
    ///   - coordinate2D: The geographic coordinate to convert.
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
    ///   - latitude: geodetic latitude.
    ///   - longitude: longitude.
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
    /// - SeeAlso: ``forward(centralMeridian:geodeticCoordinate:)``
    static func forward(centralMeridian: Double, latitude: Double, longitude: Double) -> (x: Double, y: Double, convergence: Double, centralScale: Double) {
        return forward(centralMeridian: centralMeridian, geodeticCoordinate: .init(latitude: latitude, longitude: longitude))
    }
    
    public static func reverse(centralMeridian: Double,
                        x: Double,
                        y: Double) -> (coordinate: CLLocationCoordinate2D, convergence: Double, centralScale: Double) {
        return InternalUTM.reverse(centralMeridian: centralMeridian, x: x, y: y)
    }
    public static var equatorialRadius : Double {
        return InternalUTM.EquatorialRadius
    }
    public static var flattening : Double {
        return InternalUTM.Flattening
    }
    public static var centralScale : Double {
        return InternalUTM.CentralScale
    }
}