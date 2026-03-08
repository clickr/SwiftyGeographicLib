//
//  UPSCoordinate.swift
//  SwiftGeoLib
//
//  Created by David Hart on 7/3/2026.
//


import Foundation
import UTMUPSProtocol
import Constants

/// The projected grid components of a UPS coordinate.
///
/// Groups the hemisphere, easting, and northing that identify a point on the
/// Universal Polar Stereographic grid. This is the ``Cartesian`` half of a
/// ``UPS`` value.
public struct UPSCoordinate : UTMUPSProtocol.Cartesian {
    /// The hemisphere (northern or southern pole).
    public var hemisphere: Constants.Hemisphere
    /// The easting in metres, including the 2 000 000 m false easting.
    public var easting: Double
    /// The northing in metres, including the 2 000 000 m false northing.
    public var northing: Double
}
