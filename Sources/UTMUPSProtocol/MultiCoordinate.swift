//
//  XYCoordinate.swift
//  SwiftGeographicLib
//
//  Created by David Hart on 27/7/2025.
//

import Foundation
import CoreLocation
import Constants

public protocol MultiCoordinate {
    var hemisphere: Hemisphere { get }
    var easting: Double { get }
    var northing: Double { get }
    var convergence: Double { get }
    var centralScale: Double { get }
    var geodeticCoordinate: CLLocationCoordinate2D { get }
    var latitude : CLLocationDegrees { get }
    var longitude : CLLocationDegrees { get }
}

public protocol Geodetic {
    var latitude : CLLocationDegrees { get }
    var longitude : CLLocationDegrees { get }
}

public protocol Cartesian {
    var hemisphere: Hemisphere { get }
    var easting: Double { get }
    var northing: Double { get }
}
