//
//  UTMCoordinate.swift
//  SwiftGeoLib
//
//  Created by David Hart on 7/3/2026.
//


import Foundation
import Constants
import UTMUPSProtocol

/// The projected grid components of a UTM coordinate.
///
/// Groups the zone, hemisphere, easting, and northing that identify a point
/// on the UTM grid. This is the `Cartesian` half of a ``UTM`` value.
public struct UTMCoordinate : Cartesian {
    /// The UTM zone number (1–60).
    public let zone: Int32
    /// The hemisphere of the coordinate.
    public let hemisphere: Hemisphere
    /// The easting in metres, including the 500 km false easting.
    public let easting: CartesianMetres
    /// The northing in metres, including the 10 000 km false northing in the southern hemisphere.
    public let northing: CartesianMetres
}
