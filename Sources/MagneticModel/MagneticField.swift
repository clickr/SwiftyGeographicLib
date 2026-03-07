//
//  MagneticField.swift
//  SwiftGeoLib
//
//  Created by David Hart on 7/3/2026.
//


import Foundation
import Math

/// The three-component magnetic field vector in the local (east, north, up) basis.
public struct MagneticField: Sendable {
    /// Easterly component of the magnetic field (nanotesla).
    public let Bx: Double
    /// Northerly component of the magnetic field (nanotesla).
    public let By: Double
    /// Vertical (up) component of the magnetic field (nanotesla).
    public let Bz: Double
}