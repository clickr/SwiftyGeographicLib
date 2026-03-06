//
//  UTMUPS.swift
//  SwiftGeographicLib
//
//  Created by David Hart on 27/7/2025.
//

import Foundation
import CoreLocation

public protocol UTMUPSCoordinate {
    var hemisphere : Hemisphere { get }
    var easting : Double { get }
    var northing : Double { get }
    var convergence : Double { get }
    var centralScale : Double { get }
    var locationCoordinate2D : CLLocationCoordinate2D { get }
}
