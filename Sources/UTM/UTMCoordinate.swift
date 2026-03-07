//
//  UTMCoordinate.swift
//  SwiftGeoLib
//
//  Created by David Hart on 7/3/2026.
//


import Foundation
import Constants
import UTMUPSProtocol

public struct UTMCoordinate : Cartesian {
    public let zone: Int32
    public let hemisphere: Hemisphere
    public let easting: Double
    public let northing: Double
}
