//
//  UTMError.swift
//  GeographicLibDev
//
//  Created by David Hart on 6/3/2026.
//

import Foundation

public enum UTMError : Error, Equatable {
    /// Valid zones are in the closed range [1, 60]
    case invalidZone(zone: Int32)
    /// Valid latitudes fall within [-90, 90]
    case illegalLatitude(latitude: Double)
    /// ## Easting Constraint Error
    /// ### Standard UTM
    /// Eastings must be wiithin [0m, 1,000,000m]
    /// ### MGRS
    /// Eastings must be within [100,000m, 900,000m]
    case eastingOutOfBounds(easting: Double)
    /// ## Northing Constraint Error
    /// ### Northern Hemisphere
    /// Northings must be within [-9,100,000m, 9,600,000m]
    /// ### Northern Hemisphere MGRS
    /// Northings must be within [-9,00,000m, 9,500,000m]
    /// ### Southern Hemisphere
    /// Northings must be within [900,000m, 19,600,000m]
    /// ### Southern Hemisphere MGRS
    /// Northings must be within [1000,000m, 19,500,000m]
    case northingOutOfBounds(northing: Double)
}
