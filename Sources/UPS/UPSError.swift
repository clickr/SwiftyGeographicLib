//
//  UPSError.swift
//  GeographicLibDev
//
//  Created by David Hart on 6/3/2026.
//


import Foundation

/// Errors that can occur when working with UPS coordinates.
public enum UPSError : Error, Equatable {
    /// The latitude is outside the valid range of [-90, 90] degrees.
    case invalidLatitude(latitude: Double)
    /// The latitude is within the UTM zone and cannot be represented in UPS.
    ///
    /// UPS is only valid for latitudes north of 83.5° N or south of 79.5° S.
    case latitudeOutOfBounds(latitude: Double)
    /// The easting is below the minimum allowed value.
    case eastingTooLow(easting: Double)
    /// The easting is above the maximum allowed value.
    case eastingTooHigh(easting: Double)
    /// The northing is below the minimum allowed value.
    case northingTooLow(northing: Double)
    /// The northing is above the maximum allowed value.
    case northingTooHigh(northing: Double)
}
