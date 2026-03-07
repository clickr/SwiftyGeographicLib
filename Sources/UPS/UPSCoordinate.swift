//
//  UPSCoordinate.swift
//  SwiftGeoLib
//
//  Created by David Hart on 7/3/2026.
//


import Foundation
import UTMUPSProtocol
import Constants

public struct UPSCoordinate : UTMUPSProtocol.Cartesian {
    public var hemisphere: Constants.Hemisphere
    
    public var easting: Double
    
    public var northing: Double
}
