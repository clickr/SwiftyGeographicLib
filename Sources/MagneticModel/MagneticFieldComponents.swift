//
//  MagneticFieldComponents.swift
//  SwiftGeoLib
//
//  Created by David Hart on 7/3/2026.
//


import Foundation
import Math

/// Derived geomagnetic elements.
///
/// Corresponds to the `H`, `F`, `D`, `I` output parameters of
/// `MagneticModel::FieldComponents` in the GeographicLib C++ API.
public struct MagneticFieldComponents: Sendable {
    /// Horizontal field intensity (nT).
    ///
    /// Corresponds to `H` in the GeographicLib C++ API.
    public let horizontalFieldIntensity: Double
    /// Total field intensity (nT).
    ///
    /// Corresponds to `F` in the GeographicLib C++ API.
    public let totalFieldIntensity: Double
    /// Declination (degrees east of north).
    ///
    /// Corresponds to `D` in the GeographicLib C++ API.
    public let declination: Double
    /// Inclination (degrees down from horizontal).
    ///
    /// Corresponds to `I` in the GeographicLib C++ API.
    public let inclination: Double
}
