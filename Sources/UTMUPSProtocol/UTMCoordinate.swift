//
//  UTMCoordinate.swift
//  SwiftGeoLib
//
//  Created by David Hart on 7/3/2026.
//

import Foundation
import Constants

/// A lightweight value type representing the cartesian components of a UTM coordinate.
///
/// `UTMCoordinate` holds the zone, hemisphere, easting, and northing that together
/// uniquely identify a location in the Universal Transverse Mercator grid. It does
/// not carry derived geodetic information (latitude/longitude); for a fully resolved
/// coordinate use ``UTM``.
///
/// - SeeAlso: ``UTM``, ``Cartesian``
public struct UTMCoordinate: Cartesian {
    /// The hemisphere (northern or southern) of the coordinate.
    public var hemisphere: Hemisphere

    /// The UTM zone number, in the range [1, 60].
    public var zone: Int32

    /// The easting coordinate in meters, including the 500,000 m false easting.
    public var easting: Double

    /// The northing coordinate in meters.
    ///
    /// For northern-hemisphere coordinates the origin is the equator.
    /// For southern-hemisphere coordinates a 10,000,000 m false northing has been added.
    public var northing: Double

    /// Creates a `UTMCoordinate` from its component parts.
    ///
    /// - Parameters:
    ///   - hemisphere: The hemisphere.
    ///   - zone: The UTM zone number [1, 60].
    ///   - easting: Easting in meters (including false easting).
    ///   - northing: Northing in meters (including any false northing).
    public init(hemisphere: Hemisphere, zone: Int32, easting: Double, northing: Double) {
        self.hemisphere = hemisphere
        self.zone = zone
        self.easting = easting
        self.northing = northing
    }
}
