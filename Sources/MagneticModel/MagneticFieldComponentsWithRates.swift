//
//  MagneticFieldComponentsWithRates.swift
//  SwiftGeoLib
//
//  Created by David Hart on 7/3/2026.
//


import Foundation
import Math

/// Derived geomagnetic elements with time derivatives.
///
/// Corresponds to the `H`, `F`, `D`, `I`, `Ht`, `Ft`, `Dt`, `It` output
/// parameters of `MagneticModel::FieldComponents` in the GeographicLib C++ API.
public struct MagneticFieldComponentsWithRates: Sendable {
    /// Horizontal field intensity (nT).
    ///
    /// Corresponds to `H` in the GeographicLib C++ API.
    public let horizontalFieldIntensity: Double
    /// Total field intensity (nT).
    ///
    /// Corresponds to `F` in the GeographicLib C++ API.
    public let F: Double
    /// Declination (degrees east of north).
    ///
    /// Corresponds to `D` in the GeographicLib C++ API.
    public let D: Double
    /// Inclination (degrees down from horizontal).
    ///
    /// Corresponds to `I` in the GeographicLib C++ API.
    public let I: Double
    /// Rate of change of horizontal field intensity (nT/yr).
    ///
    /// Corresponds to `Ht` in the GeographicLib C++ API.
    public let horizontalFieldIntensityDeltaT: Double
    /// Rate of change of total field intensity (nT/yr).
    ///
    /// Corresponds to `Ft` in the GeographicLib C++ API.
    public let totalIntensityDeltaT: Double
    /// Rate of change of declination (degrees/yr).
    ///
    /// Corresponds to `Dt` in the GeographicLib C++ API.
    public let declinationDeltaT: Double
    /// Rate of change of inclination (degrees/yr).
    ///
    /// Corresponds to `It` in the GeographicLib C++ API.
    public let inclinationDeltaT: Double
}
