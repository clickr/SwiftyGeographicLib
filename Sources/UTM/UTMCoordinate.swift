//
//  UTMCoordinate.swift
//  SwiftGeoLib
//
//  Created by David Hart on 7/3/2026.
//


import Foundation
import Constants

public struct UTMCoordinate {
    public let zone: Int32
    public let hemisphere: Hemisphere
    public let easting: Double
    public let northing: Double
}
