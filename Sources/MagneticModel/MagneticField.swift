//
//  MagneticField.swift
//  SwiftGeoLib
//
//  Created by David Hart on 7/3/2026.
//


import Foundation
import Math

/// The three-component magnetic field vector in the local (east, north, up) basis.
///
/// Corresponds to the `Bx`, `By`, `Bz` output parameters of
/// `MagneticModel::operator()` in the GeographicLib C++ API.
public struct MagneticField: Sendable {
    /// Easterly component of the magnetic field (nanotesla).
    ///
    /// Corresponds to `Bx` in the GeographicLib C++ API.
    public let east: Double
    /// Northerly component of the magnetic field (nanotesla).
    ///
    /// Corresponds to `By` in the GeographicLib C++ API.
    public let north: Double
    /// Vertical (up) component of the magnetic field (nanotesla).
    ///
    /// Corresponds to `Bz` in the GeographicLib C++ API.
    public let up: Double
}