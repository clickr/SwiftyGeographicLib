//
//  MagneticFieldWithRates.swift
//  SwiftGeoLib
//
//  Created by David Hart on 7/3/2026.
//


import Foundation
import Math

/// The magnetic field vector together with its time derivatives.
///
/// Corresponds to the `Bx`, `By`, `Bz`, `Bxt`, `Byt`, `Bzt` output
/// parameters of `MagneticModel::operator()` in the GeographicLib C++ API.
public struct MagneticFieldWithRates: Sendable {
    /// The magnetic field.
    public let field: MagneticField
    /// Rate of change of the easterly component (nT/yr).
    ///
    /// Corresponds to `Bxt` in the GeographicLib C++ API.
    public let eastDeltaT: Double
    /// Rate of change of the northerly component (nT/yr).
    ///
    /// Corresponds to `Byt` in the GeographicLib C++ API.
    public let northDeltaT: Double
    /// Rate of change of the vertical (up) component (nT/yr).
    ///
    /// Corresponds to `Bzt` in the GeographicLib C++ API.
    public let upDeltaT: Double
}