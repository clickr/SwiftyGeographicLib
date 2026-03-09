//
//  XYCoordinate.swift
//  SwiftGeographicLib
//
//  Created by David Hart on 27/7/2025.
//

import Foundation
import CoreLocation
@_exported import Constants

/// A distance in metres on a projected Cartesian grid (easting or northing).
public typealias CartesianMetres = Double

/// A type that provides both geodetic (latitude/longitude) and projected
/// (easting/northing) representations of a geographic coordinate.
///
/// Conforming types (``UTM`` and ``UPS``) expose the full set of projection
/// outputs: hemisphere, metric grid coordinates, the original geodetic
/// position, and projection diagnostics (convergence and scale).
public protocol MultiCoordinate {
    /// The hemisphere of the projected coordinate.
    var hemisphere: Hemisphere { get }
    /// The easting in metres, including any false easting.
    var easting: CartesianMetres { get }
    /// The northing in metres, including any false northing.
    var northing: CartesianMetres { get }
    /// The meridian convergence at the point, in degrees.
    var convergence: Double { get }
    /// The scale factor of the projection at the point.
    var centralScale: Double { get }
    /// The geodetic coordinate (latitude and longitude) of the point.
    var geodeticCoordinate: CLLocationCoordinate2D { get }
    /// The latitude in degrees.
    var latitude : CLLocationDegrees { get }
    /// The longitude in degrees.
    var longitude : CLLocationDegrees { get }
}

/// A type that exposes a geodetic position as latitude and longitude in degrees.
public protocol Geodetic {
    /// The latitude in degrees.
    var latitude : CLLocationDegrees { get }
    /// The longitude in degrees.
    var longitude : CLLocationDegrees { get }
}

/// A type that exposes projected grid coordinates: hemisphere, easting, and northing.
public protocol Cartesian {
    /// The hemisphere of the projected coordinate.
    var hemisphere: Hemisphere { get }
    /// The easting in metres.
    var easting: CartesianMetres { get }
    /// The northing in metres.
    var northing: CartesianMetres { get }
}
