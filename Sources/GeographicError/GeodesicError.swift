//
//  GeodesicError.swift
//  SwiftGeographicLib
//
//  Created by David Hart on 14/8/2025.
//

/**
 Represents errors that can occur when initializing or working with geodesic shapes and ellipsoid parameters.

 - `equatorialRadiusNotPositive`: The provided equatorial radius is zero or negative. Ellipsoid radii must be positive nonzero values.
 - `polarSemiAxisNotPositive`: The provided polar semi-axis is zero or negative. Ellipsoid axes must be positive nonzero values.
*/
public enum GeodesicError : Error {
    /// The provided equatorial radius is zero or negative.
    case equatorialRadiusNotPositive
    /// The provided polar semi-axis is zero or negative.
    case polarSemiAxisNotPositive
}
