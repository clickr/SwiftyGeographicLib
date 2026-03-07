//
//  MagneticFieldWithRates.swift
//  SwiftGeoLib
//
//  Created by David Hart on 7/3/2026.
//


import Foundation
import Math

/// The magnetic field vector together with its time derivatives.
public struct MagneticFieldWithRates: Sendable {
    /// The magnetic field.
    public let field: MagneticField
    /// Rate of change of the easterly component (nT/yr).
    public let eastDeltaT: Double
    /// Rate of change of the northerly component (nT/yr).
    public let northDeltaT: Double
    /// Rate of change of the vertical (up) component (nT/yr).
    public let upDeltaT: Double
}